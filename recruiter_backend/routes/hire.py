from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus, JobApplication, Rating
from shared.models.user import Recruiter, Tasker
from shared.models.transaction import Transaction
from recruiter_backend.routes.auth import get_current_recruiter
from shared.services.escrow import escrow
from shared.services.notifications import send_push
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

router = APIRouter(prefix="/hire", tags=["Hire"])

class HireRequest(BaseModel):
    application_id: int

class RatingRequest(BaseModel):
    stars: int
    review: Optional[str] = None

@router.get("/applications")
async def get_all_applications(
    status: Optional[str] = None,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Get all applications for recruiter's jobs"""
    
    # Get recruiter's jobs
    job_ids = [j.id for j in db.query(Job.id).filter_by(recruiter_id=current_recruiter.id).all()]
    
    if not job_ids:
        return {"applications": []}
    
    # Get applications for those jobs
    query = db.query(JobApplication).filter(JobApplication.job_id.in_(job_ids))
    
    if status:
        query = query.filter_by(status=status)
    
    applications = query.order_by(JobApplication.created_at.desc()).all()
    
    result = []
    for app in applications:
        job = db.query(Job).filter_by(id=app.job_id).first()
        tasker = db.query(Tasker).filter_by(id=app.tasker_id).first()
        result.append({
            "application_id": app.id,
            "job": job.to_dict() if job else None,
            "tasker": tasker.to_dict() if tasker else None,
            "message": app.message,
            "status": app.status,
            "applied_at": app.created_at.isoformat()
        })
    
    return {"applications": result}

@router.post("/hire")
async def hire_tasker(
    request: HireRequest,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Accept an application and assign tasker to job"""
    
    # Get application
    application = db.query(JobApplication).filter_by(id=request.application_id).first()
    
    if not application:
        raise HTTPException(404, "Application not found")
    
    # Verify job belongs to recruiter
    job = db.query(Job).filter_by(
        id=application.job_id,
        recruiter_id=current_recruiter.id
    ).first()
    
    if not job:
        raise HTTPException(404, "Job not found or not owned by you")
    
    if job.status != JobStatus.OPEN:
        raise HTTPException(400, "Job is no longer open")
    
    # Assign tasker and update job status
    job.tasker_id = application.tasker_id
    job.status = JobStatus.ASSIGNED
    job.assigned_at = datetime.utcnow()
    
    # Update application
    application.status = "accepted"
    application.responded_at = datetime.utcnow()
    
    # Reject other applications for this job
    other_apps = db.query(JobApplication).filter(
        JobApplication.job_id == application.job_id,
        JobApplication.id != application.id
    ).all()
    
    for other_app in other_apps:
        other_app.status = "rejected"
        other_app.responded_at = datetime.utcnow()
    
    db.commit()
    
    # Notify accepted tasker
    send_push(
        user_id=application.tasker_id,
        user_type="tasker",
        title="Job Offer Accepted! 🎉",
        body=f"You've been hired for: {job.title}",
        data={"job_id": job.id},
        db=db
    )
    
    # Notify rejected taskers
    for other_app in other_apps:
        send_push(
            user_id=other_app.tasker_id,
            user_type="tasker",
            title="Application Update",
            body=f"Another tasker was selected for: {job.title}",
            db=db
        )
    
    return {
        "message": "Tasker hired successfully",
        "job_id": job.id,
        "tasker_id": application.tasker_id
    }

@router.post("/{job_id}/mark-completed")
async def mark_job_completed(
    job_id: int,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Mark job as completed and release payment"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status != JobStatus.IN_PROGRESS:
        raise HTTPException(400, "Job must be in progress to mark as completed")
    
    # Release payment using escrow service
    try:
        await escrow.release_payment(
            db=db,
            job_id=job_id,
            released_by="recruiter"
        )
        
        return {
            "message": "Job marked as completed and payment released",
            "job_id": job.id
        }
    
    except Exception as e:
        raise HTTPException(500, f"Failed to complete job: {str(e)}")

@router.post("/{job_id}/dispute")
async def dispute_job(
    job_id: int,
    reason: str,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Dispute a job (refund payment)"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status not in [JobStatus.IN_PROGRESS, JobStatus.ASSIGNED]:
        raise HTTPException(400, "Job cannot be disputed in this status")
    
    # Use escrow to refund
    try:
        await escrow.refund_payment(
            db=db,
            job_id=job_id,
            reason=reason
        )
        
        return {
            "message": "Job disputed and payment refunded",
            "job_id": job.id
        }
    
    except Exception as e:
        raise HTTPException(500, f"Failed to dispute job: {str(e)}")

@router.post("/{job_id}/rate")
async def rate_tasker(
    job_id: int,
    request: RatingRequest,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Rate a completed job and tasker"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status != JobStatus.COMPLETED:
        raise HTTPException(400, "Only completed jobs can be rated")
    
    if request.stars < 1 or request.stars > 5:
        raise HTTPException(400, "Stars must be between 1 and 5")
    
    # Check if rating already exists
    existing_rating = db.query(Rating).filter_by(
        job_id=job_id,
        recruiter_id=current_recruiter.id
    ).first()
    
    if existing_rating:
        raise HTTPException(400, "You have already rated this job")
    
    # Create rating
    rating = Rating(
        job_id=job.id,
        tasker_id=job.tasker_id,
        recruiter_id=current_recruiter.id,
        stars=request.stars,
        review=request.review
    )
    
    db.add(rating)
    db.commit()
    db.refresh(rating)
    
    # Update tasker's rating (simple average)
    tasker = db.query(Tasker).filter_by(id=job.tasker_id).first()
    if tasker:
        all_ratings = db.query(Rating).filter_by(tasker_id=tasker.id).all()
        if all_ratings:
            avg_rating = sum(r.stars for r in all_ratings) / len(all_ratings)
            tasker.rating = avg_rating
            db.commit()
    
    # Notify tasker
    send_push(
        user_id=job.tasker_id,
        user_type="tasker",
        title="Job Rating",
        body=f"You received a {request.stars} star rating for Job #{job.id}",
        db=db
    )
    
    return {
        "message": "Rating submitted successfully",
        "rating_id": rating.id,
        "stars": rating.stars
    }
