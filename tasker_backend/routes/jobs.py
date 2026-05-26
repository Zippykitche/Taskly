from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobApplication, JobStatus
from shared.models.user import Tasker
from tasker_backend.routes.auth import get_current_tasker

router = APIRouter()


class MessagePayload(BaseModel):
    message: str | None = None


@router.get("/", response_model=list[dict])
def list_open_jobs(db: Session = Depends(get_db)):
    jobs = db.query(Job).filter(Job.status == JobStatus.OPEN).all()
    return [job.to_dict() for job in jobs]


@router.get("/me", response_model=list[dict])
def my_jobs(current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    jobs = db.query(Job).filter(Job.tasker_id == current_tasker.id).all()
    return [job.to_dict() for job in jobs]


@router.post("/{job_id}/apply")
def apply_to_job(job_id: int, payload: MessagePayload, current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.status == JobStatus.OPEN).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found or not open")
    existing = db.query(JobApplication).filter(JobApplication.job_id == job_id, JobApplication.tasker_id == current_tasker.id).first()
    if existing:
        raise HTTPException(status_code=400, detail="You already applied to this job")
    application = JobApplication(job_id=job.id, tasker_id=current_tasker.id, message=payload.message)
    db.add(application)
    db.commit()
    db.refresh(application)
    return {"id": application.id, "status": application.status, "job_id": job.id}
