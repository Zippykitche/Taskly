import base64
from datetime import datetime
import requests
from fastapi import APIRouter, Depends, HTTPException, Body, Request
from sqlalchemy.orm import Session
import auth, models, schemas

router = APIRouter()

# --- Daraja Sandbox Credentials (Should be in .env) ---
CONSUMER_KEY = "5rluGJWA2aHY7uE0y6dW2URxe49Np5QavIS6k6I5zfAvLbUT"
CONSUMER_SECRET = "gtR3WUkltaQcXf7LGf3N8qYpyoUqZcw2vPTQeoEh06s05f0v8Cxg14BiU3OjQKOL"
PASSKEY = "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"
BUSINESS_SHORTCODE = "174379"
CALLBACK_URL = "https://your-ngrok-url.ngrok-free.app/payments/callback"

def get_mpesa_access_token():
    url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
    response = requests.get(url, auth=(CONSUMER_KEY, CONSUMER_SECRET))
    return response.json().get("access_token")

@router.post("/stkpush")
def initiate_stk_push(
    payload: schemas.StkPushRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """Trigger the M-Pesa PIN popup on the user's phone"""
    access_token = get_mpesa_access_token()
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    password = base64.b64encode(f"{BUSINESS_SHORTCODE}{PASSKEY}{timestamp}".encode()).decode()
    
    headers = {"Authorization": f"Bearer {access_token}"}
    
    stk_payload = {
        "BusinessShortCode": BUSINESS_SHORTCODE,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": payload.amount,
        "PartyA": payload.phone,
        "PartyB": BUSINESS_SHORTCODE,
        "PhoneNumber": payload.phone,
        "CallBackURL": CALLBACK_URL,
        "AccountReference": f"Booking_{payload.booking_id}",
        "TransactionDesc": "SnapTask Payment"
    }
    
    response = requests.post(
        "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/query", # Sandbox URL
        json=stk_payload, 
        headers=headers
    )
    
    res_data = response.json()
    
    if res_data.get("ResponseCode") == "0":
        # Create a pending transaction record
        new_tx = models.Transaction(
            booking_id=payload.booking_id,
            user_id=current_user.id,
            amount=payload.amount,
            phone=payload.phone,
            checkout_request_id=res_data.get("CheckoutRequestID"),
            merchant_request_id=res_data.get("MerchantRequestID"),
            status="pending"
        )
        db.add(new_tx)
        db.commit()
        return {"message": "STK Push initiated", "checkout_id": new_tx.checkout_request_id}
    
    raise HTTPException(status_code=400, detail="Failed to initiate STK Push")

@router.post("/callback")
async def mpesa_callback(request: Request, db: Session = Depends(auth.get_db)):
    """
    Safaricom calls this endpoint with the payment result.
    """
    data = await request.json()
    result = data['Body']['stkCallback']
    checkout_id = result['CheckoutRequestID']
    result_code = result['ResultCode']
    
    # Find our internal transaction record
    transaction = db.query(models.Transaction).filter(
        models.Transaction.checkout_request_id == checkout_id
    ).first()
    
    if not transaction:
        return {"ResultCode": 1, "ResultDesc": "Transaction not found"}

    if result_code == 0:
        # SUCCESS
        transaction.status = "success"
        
        # Extract Receipt Number from CallbackMetadata
        items = result['CallbackMetadata']['Item']
        receipt = next((i['Value'] for i in items if i['Name'] == 'MpesaReceiptNumber'), None)
        transaction.receipt_number = receipt
        
        # Update Booking Status if needed
        booking = db.query(models.Booking).filter(models.Booking.id == transaction.booking_id).first()
        if booking:
            booking.status = models.BookingStatus.accepted # Or a custom 'paid' status
            
            # Notify the user
            new_notif = models.Notification(
                user_id=transaction.user_id,
                message=f"Payment of KES {transaction.amount} successful! Receipt: {receipt}"
            )
            db.add(new_notif)
            
    else:
        # FAILED (Cancelled, Wrong PIN, etc)
        transaction.status = "failed"
        
        new_notif = models.Notification(
            user_id=transaction.user_id,
            message=f"Payment for booking failed: {result['ResultDesc']}"
        )
        db.add(new_notif)

    db.commit()
    return {"ResultCode": 0, "ResultDesc": "Success"}