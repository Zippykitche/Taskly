from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus
from shared.models.transaction import Transaction, TransactionStatus
from shared.models.user import Recruiter
from shared.services.mpesa import MPesaClient
from recruiter_backend.routes.auth import get_current_recruiter

router = APIRouter()
mpesa_client = MPesaClient()


@router.post("/pay/{job_id}")
async def pay_for_job(job_id: int, current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_recruiter.id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    if job.status != JobStatus.OPEN:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Job cannot be paid at this stage")
    transaction = db.query(Transaction).filter(Transaction.job_id == job.id).first()
    if not transaction:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transaction not found")
    transaction.status = TransactionStatus.ESCROWED
    transaction.paid_at = transaction.created_at
    transaction.escrowed_at = transaction.created_at
    db.commit()
    return {"transaction_id": transaction.id, "status": transaction.status.value}


@router.get("/transactions")
def transaction_history(current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    transactions = db.query(Transaction).filter(Transaction.recruiter_id == current_recruiter.id).all()
    return [transaction.to_dict() for transaction in transactions]
