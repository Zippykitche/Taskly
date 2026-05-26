from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.user import Wallet, Tasker
from shared.models.transaction import Withdrawal
from tasker_backend.routes.auth import get_current_tasker

router = APIRouter()


class WithdrawRequest(BaseModel):
    amount: int


@router.get("/wallet")
def get_wallet(current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    wallet = db.query(Wallet).filter(Wallet.tasker_id == current_tasker.id).first()
    if not wallet:
        wallet = Wallet(tasker_id=current_tasker.id)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
    return {
        "available_balance": wallet.available_balance / 100,
        "pending_balance": wallet.pending_balance / 100,
        "total_earned": wallet.total_earned / 100,
        "total_withdrawn": wallet.total_withdrawn / 100,
    }


@router.post("/withdraw")
def request_withdrawal(request: WithdrawRequest, current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    if request.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be greater than zero")
    wallet = db.query(Wallet).filter(Wallet.tasker_id == current_tasker.id).first()
    if not wallet or wallet.available_balance < request.amount:
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")
    wallet.available_balance -= request.amount
    wallet.pending_withdrawals += request.amount
    withdrawal = Withdrawal(tasker_id=current_tasker.id, amount=request.amount)
    db.add(withdrawal)
    db.commit()
    db.refresh(withdrawal)
    return {"id": withdrawal.id, "status": withdrawal.status}
