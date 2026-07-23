from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus
from shared.models.transaction import Transaction, TransactionStatus
from shared.models.user import Recruiter
from recruiter_backend.routes.auth import get_current_recruiter
from . import auth
from shared.services.escrow import escrow
from shared.services.notifications import send_push
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

router = APIRouter(prefix="/payments", tags=["Payments"])

class PaymentRequest(BaseModel):
    job_id: int
    phone_number: str

@router.post("/initiate")
async def initiate_payment(
    request: PaymentRequest,
    current_user: dict = Depends(auth.get_current_recruiter),  # For recruiter backend
    db: Session = Depends(get_db)
):
    """Initiate payment for a job via M-Pesa STK Push"""
    
    # Verify job belongs to recruiter
    job = db.query(Job).filter_by(id=request.job_id, recruiter_id=current_user.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status != JobStatus.OPEN:
        raise HTTPException(400, "Can only pay for open jobs")
    
    # Check if transaction already exists
    existing_transaction = db.query(Transaction).filter_by(job_id=request.job_id).first()
    
    if existing_transaction and existing_transaction.status != TransactionStatus.FAILED:
        raise HTTPException(400, f"Payment already in process: {existing_transaction.status.value}")
    
    # If tasker not yet assigned, use placeholder
    tasker_id = job.tasker_id or 0
    
    # Use escrow service to initiate payment
    try:
        transaction = await escrow.initiate_payment(
            db=db,
            job_id=request.job_id,
            recruiter_id=current_user.id,
            tasker_id=tasker_id,
            total_amount=job.price,
            phone_number=request.phone_number
        )
        
        # Notify recruiter
        send_push(
            user_id=current_user.id,
            user_type="recruiter",
            title="Payment Initiated",
            body=f"Enter M-Pesa PIN to complete payment for Job #{job.id}",
            db=db
        )
        
        return {
            "message": "Payment initiated. Please enter M-Pesa PIN on your phone.",
            "transaction_id": transaction.id,
            "amount": job.price / 100
        }
    
    except Exception as e:
        raise HTTPException(500, f"Payment initiation failed: {str(e)}")

@router.get("/transactions")
async def get_transaction_history(
    status: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
    current_user: dict = Depends(auth.get_current_recruiter),  # For recruiter backend
    db: Session = Depends(get_db)
):
    """Get recruiter's transaction history"""
    
    query = db.query(Transaction).filter_by(recruiter_id=current_user.id)
    
    if status:
        try:
            status_enum = TransactionStatus[status.upper()]
            query = query.filter_by(status=status_enum)
        except KeyError:
            pass  # Invalid status, ignore
    
    transactions = query.order_by(Transaction.created_at.desc()).offset(offset).limit(limit).all()
    total = query.count()
    
    return {
        "transactions": [t.to_dict() for t in transactions],
        "total": total
    }

@router.get("/{transaction_id}")
async def get_transaction(
    transaction_id: int,
    current_user: dict = Depends(auth.get_current_recruiter),  # For recruiter backend
    db: Session = Depends(get_db)
):
    """Get transaction details"""
    
    transaction = db.query(Transaction).filter_by(
        id=transaction_id,
        recruiter_id=current_user.id
    ).first()
    
    if not transaction:
        raise HTTPException(404, "Transaction not found")
    
    return transaction.to_dict()

@router.post("/mpesa/callback")
async def mpesa_stk_callback(
    result: dict,
    db: Session = Depends(get_db)
):
    """M-Pesa STK Push callback webhook"""
    
    try:
        body = result.get("Body", {})
        stk_callback = body.get("stkCallback", {})
        
        merchant_request_id = stk_callback.get("MerchantRequestID")
        checkout_request_id = stk_callback.get("CheckoutRequestID")
        result_code = stk_callback.get("ResultCode")
        result_desc = stk_callback.get("ResultDesc")
        
        # Find transaction by checkout request ID (stored in mpesa_transaction_id)
        transaction = db.query(Transaction).filter_by(
            mpesa_transaction_id=checkout_request_id
        ).first()
        
        if not transaction:
            return {"ResultCode": 1, "ResultDesc": "Transaction not found"}
        
        if result_code == 0:  # Success
            # Get callback metadata
            callback_metadata = stk_callback.get("CallbackMetadata", {})
            items = {item["Name"]: item["Value"] for item in callback_metadata.get("Item", [])}
            
            receipt_number = items.get("MpesaReceiptNumber")
            
            # Confirm payment using escrow service
            escrow.confirm_payment(
                db=db,
                transaction_id=transaction.id,
                mpesa_receipt=receipt_number
            )
        else:  # Payment failed
            transaction.status = TransactionStatus.FAILED
            db.commit()
        
        return {"ResultCode": 0, "ResultDesc": "Accepted"}
    
    except Exception as e:
        return {"ResultCode": 1, "ResultDesc": f"Error: {str(e)}"}
