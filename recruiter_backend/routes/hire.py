from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus
from shared.models.transaction import Transaction, TransactionStatus
from shared.models.job import Rating
from shared.models.user import Recruiter
from recruiter_backend.routes.auth import get_current_recruiter

router = APIRouter()


@router.post("/{job_id}/assign/{tasker_id}")
def assign_tasker(job_id: int, tasker_id: int, current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_recruiter.id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    if job.status != JobStatus.OPEN:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Job is not open")
    job.tasker_id = tasker_id
    job.status = JobStatus.ASSIGNED
    job.assigned_at = datetime.utcnow()
    db.commit()
    return {"job_id": job.id, "tasker_id": job.tasker_id, "status": job.status.value}


@router.post("/{job_id}/complete")
def complete_job(job_id: int, current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_recruiter.id).first()
    if not job or job.status != JobStatus.ASSIGNED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Job cannot be completed")
    job.status = JobStatus.COMPLETED
    job.completed_at = datetime.utcnow()
    transaction = db.query(Transaction).filter(Transaction.job_id == job.id).first()
    if transaction:
        transaction.status = TransactionStatus.RELEASED
        transaction.released_at = datetime.utcnow()
    db.commit()
    return {"job_id": job.id, "status": job.status.value}


class RatingPayload(BaseModel):
    stars: int
    review: str | None = None


@router.post("/{job_id}/rate")
def rate_tasker(job_id: int, payload: RatingPayload, current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_recruiter.id).first()
    if not job or job.status != JobStatus.COMPLETED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only completed jobs can be rated")
    if payload.stars < 1 or payload.stars > 5:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Stars must be between 1 and 5")
    rating = Rating(
        job_id=job.id,
        tasker_id=job.tasker_id or 0,
        recruiter_id=current_recruiter.id,
        stars=payload.stars,
        review=payload.review,
    )
    db.add(rating)
    db.commit()
    db.refresh(rating)
    return {"id": rating.id, "stars": rating.stars, "review": rating.review}
