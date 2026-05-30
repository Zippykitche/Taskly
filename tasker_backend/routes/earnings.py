from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.user import Tasker, Wallet
from shared.models.transaction import Transaction, Withdrawal
from tasker_backend.routes.auth import get_current_tasker
from shared.services.mpesa import mpesa_client
from shared.services.notifications import send_push
from datetime import datetime
import os

router = APIRouter(prefix="/earnings", tags=["Earnings"])

@router.get("/wallet")
async def get_wallet(
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get wallet balance and stats"""
    
    wallet = db.query(Wallet).filter_by(tasker_id=current_tasker.id).first()
    
    if not wallet:
        wallet = Wallet(tasker_id=current_tasker.id)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
    
    return {
        "available_balance": wallet.available_balance / 100,  # Convert to KES
        "pending_balance": wallet.pending_balance / 100,
        "pending_withdrawals": wallet.pending_withdrawals / 100,
        "total_earned": wallet.total_earned / 100,
        "total_withdrawn": wallet.total_withdrawn / 100
    }

@router.get("/transactions")
async def get_transaction_history(
    limit: int = 20,
    offset: int = 0,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get earning history"""
    
    transactions = db.query(Transaction).filter_by(
        tasker_id=current_tasker.id
    ).order_by(Transaction.created_at.desc()).offset(offset).limit(limit).all()
    
    return {
        "transactions": [t.to_dict() for t in transactions]
    }

@router.post("/withdraw")
async def request_withdrawal(
    amount: int,  # In KES (will convert to cents)
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Request M-Pesa withdrawal"""
    
    amount_cents = amount * 100  # Convert to cents
    
    # Get wallet
    wallet = db.query(Wallet).filter_by(tasker_id=current_tasker.id).first()
    
    if not wallet or wallet.available_balance < amount_cents:
        raise HTTPException(400, "Insufficient balance")
    
    if amount < 100:
        raise HTTPException(400, "Minimum withdrawal is KES 100")
    
    # Create withdrawal record
    withdrawal = Withdrawal(
        tasker_id=current_tasker.id,
        amount=amount_cents,
        status="pending"
    )
    
    db.add(withdrawal)
    
    # Deduct from available, add to pending withdrawals
    wallet.available_balance -= amount_cents
    wallet.pending_withdrawals += amount_cents
    
    db.commit()
    db.refresh(withdrawal)
    
    # Initiate M-Pesa B2C payment
    try:
        result_url = f"{os.getenv('API_BASE_URL')}/earnings/mpesa/withdrawal-result"
        timeout_url = f"{os.getenv('API_BASE_URL')}/earnings/mpesa/withdrawal-timeout"
        
        response = await mpesa_client.b2c_payment(
            phone_number=current_tasker.phone_number,
            amount=amount,
            remarks=f"Taskly withdrawal for {current_tasker.full_name}",
            result_url=result_url,
            timeout_url=timeout_url
        )
        
        if response.get("ResponseCode") == "0":
            withdrawal.mpesa_conversation_id = response.get("ConversationID")
            db.commit()
            
            return {
                "message": "Withdrawal initiated. You'll receive M-Pesa within 5 minutes.",
                "withdrawal_id": withdrawal.id,
                "amount": amount
            }
        else:
            # Revert on failure
            wallet.available_balance += amount_cents
            wallet.pending_withdrawals -= amount_cents
            withdrawal.status = "failed"
            db.commit()
            
            raise HTTPException(500, f"M-Pesa error: {response.get('errorMessage')}")
    
    except Exception as e:
        # Revert on exception
        wallet.available_balance += amount_cents
        wallet.pending_withdrawals -= amount_cents
        withdrawal.status = "failed"
        db.commit()
        
        raise HTTPException(500, f"Withdrawal failed: {str(e)}")

@router.post("/mpesa/withdrawal-result")
async def mpesa_withdrawal_callback(result: dict, db: Session = Depends(get_db)):
    """M-Pesa B2C result callback"""
    
    conversation_id = result["Result"]["ConversationID"]
    result_code = result["Result"]["ResultCode"]
    
    withdrawal = db.query(Withdrawal).filter_by(
        mpesa_conversation_id=conversation_id
    ).first()
    
    if not withdrawal:
        return {"message": "Withdrawal not found"}
    
    wallet = db.query(Wallet).filter_by(tasker_id=withdrawal.tasker_id).first()
    
    if result_code == 0:  # Success
        withdrawal.status = "completed"
        withdrawal.mpesa_result_code = str(result_code)
        withdrawal.completed_at = datetime.utcnow()
        
        wallet.pending_withdrawals -= withdrawal.amount
        wallet.total_withdrawn += withdrawal.amount
        
        # Notify tasker
        send_push(
            user_id=withdrawal.tasker_id,
            user_type="tasker",
            title="Withdrawal Successful! 💰",
            body=f"KES {withdrawal.amount/100:.2f} has been sent to your M-Pesa",
            db=db
        )
    else:  # Failed
        withdrawal.status = "failed"
        withdrawal.mpesa_result_code = str(result_code)
        
        # Refund to available balance
        wallet.available_balance += withdrawal.amount
        wallet.pending_withdrawals -= withdrawal.amount
        
        # Notify tasker
        send_push(
            user_id=withdrawal.tasker_id,
            user_type="tasker",
            title="Withdrawal Failed",
            body=f"Your withdrawal of KES {withdrawal.amount/100:.2f} failed. Amount refunded.",
            db=db
        )
    
    db.commit()
    
    return {"ResultCode": 0, "ResultDesc": "Accepted"}
