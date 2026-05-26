from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.user import Tasker
from shared.models.job import Job, JobStatus, JobApplication
from shared.auth import get_current_tasker
from shared.services.earl_ai import earl_client
from shared.services.notifications import send_push
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/jobs", tags=["Jobs"])

@router.get("/browse")
async def browse_jobs(
    category: Optional[str] = None,
    location_city: Optional[str] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    urgency: Optional[str] = None,
    skip: int = 0,
    limit: int = 20,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Browse available jobs with filters"""
    
    query = db.query(Job).filter(Job.status == JobStatus.OPEN)
    
    # Apply filters
    if category:
        query = query.filter(Job.category == category)
    
    if location_city:
        query = query.filter(Job.location_city == location_city)
    
    if min_price:
        query = query.filter(Job.price >= min_price * 100)  # Convert to cents
    
    if max_price:
        query = query.filter(Job.price <= max_price * 100)
    
    if urgency:
        query = query.filter(Job.urgency == urgency)
    
    # Filter by tasker's categories
    if current_tasker.categories:
        query = query.filter(Job.category.in_(current_tasker.categories))
    
    jobs = query.order_by(Job.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "jobs": [job.to_dict() for job in jobs],
        "total": query.count()
    }

@router.get("/recommended")
async def get_recommended_jobs(
    limit: int = 10,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get AI-recommended jobs for this tasker"""
    
    # Get available jobs in tasker's categories
    jobs = db.query(Job).filter(
        Job.status == JobStatus.OPEN,
        Job.category.in_(current_tasker.categories),
        Job.location_city == current_tasker.location_city
    ).limit(50).all()
    
    if not jobs:
        return {"jobs": [], "message": "No jobs available in your area"}
    
    # Get AI rankings from E.A.R.L
    try:
        tasker_profile = {
            "id": current_tasker.id,
            "categories": current_tasker.categories,
            "rating": current_tasker.rating,
            "jobs_completed": current_tasker.jobs_completed,
            "location": current_tasker.location_city
        }
        
        jobs_data = [
            {
                "id": job.id,
                "title": job.title,
                "category": job.category,
                "price": job.price / 100,
                "location": f"{job.location_area}, {job.location_city}",
                "urgency": job.urgency
            }
            for job in jobs
        ]
        
        ranked_jobs = await earl_client.rank_jobs_for_tasker(
            tasker_profile=tasker_profile,
            jobs=jobs_data
        )
        
        # Reorder jobs based on AI ranking
        job_map = {job.id: job for job in jobs}
        recommended = []
        
        for ranking in ranked_jobs[:limit]:
            job = job_map.get(ranking["job_id"])
            if job:
                job_dict = job.to_dict()
                job_dict["match_score"] = ranking["match_score"]
                job_dict["match_reason"] = ranking["why"]
                recommended.append(job_dict)
        
        return {"jobs": recommended}
    
    except Exception as e:
        # Fallback to simple sorting if AI fails
        return {
            "jobs": [job.to_dict() for job in jobs[:limit]],
            "error": "AI ranking unavailable, showing recent jobs"
        }

@router.get("/{job_id}")
async def get_job_details(
    job_id: int,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get detailed job information"""
    
    job = db.query(Job).filter_by(id=job_id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    # Check if tasker already applied
    application = db.query(JobApplication).filter_by(
        job_id=job_id,
        tasker_id=current_tasker.id
    ).first()
    
    job_dict = job.to_dict()
    job_dict["already_applied"] = application is not None
    job_dict["application_status"] = application.status if application else None
    
    return job_dict

@router.post("/{job_id}/apply")
async def apply_for_job(
    job_id: int,
    message: Optional[str] = None,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Apply for a job"""
    
    job = db.query(Job).filter_by(id=job_id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status != JobStatus.OPEN:
        raise HTTPException(400, "Job is no longer available")
    
    # Check if already applied
    existing = db.query(JobApplication).filter_by(
        job_id=job_id,
        tasker_id=current_tasker.id
    ).first()
    
    if existing:
        raise HTTPException(400, "You have already applied to this job")
    
    # Verify tasker has the required skill
    if job.category not in current_tasker.categories:
        raise HTTPException(400, f"You don't have {job.category} in your skills")
    
    # Create application
    application = JobApplication(
        job_id=job_id,
        tasker_id=current_tasker.id,
        message=message,
        status="pending"
    )
    
    db.add(application)
    db.commit()
    
    # Notify recruiter
    send_push(
        user_id=job.recruiter_id,
        user_type="recruiter",
        title="New Application",
        body=f"{current_tasker.full_name} applied for your job: {job.title}",
        db=db
    )
    
    return {
        "message": "Application submitted successfully",
        "application_id": application.id
    }

@router.get("/my/applications")
async def get_my_applications(
    status: Optional[str] = None,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get tasker's job applications"""
    
    query = db.query(JobApplication).filter_by(tasker_id=current_tasker.id)
    
    if status:
        query = query.filter_by(status=status)
    
    applications = query.order_by(JobApplication.created_at.desc()).all()
    
    result = []
    for app in applications:
        job = db.query(Job).filter_by(id=app.job_id).first()
        result.append({
            "application_id": app.id,
            "job": job.to_dict() if job else None,
            "status": app.status,
            "applied_at": app.created_at.isoformat(),
            "message": app.message
        })
    
    return {"applications": result}

@router.get("/my/active")
async def get_active_jobs(
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get tasker's active/assigned jobs"""
    
    jobs = db.query(Job).filter(
        Job.tasker_id == current_tasker.id,
        Job.status.in_([JobStatus.ASSIGNED, JobStatus.IN_PROGRESS])
    ).all()
    
    return {"jobs": [job.to_dict() for job in jobs]}

@router.post("/{job_id}/start")
async def start_job(
    job_id: int,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Mark job as started"""
    
    job = db.query(Job).filter_by(id=job_id, tasker_id=current_tasker.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found or not assigned to you")
    
    if job.status != JobStatus.ASSIGNED:
        raise HTTPException(400, "Job cannot be started")
    
    job.status = JobStatus.IN_PROGRESS
    job.started_at = datetime.utcnow()
    
    db.commit()
    
    # Notify recruiter
    send_push(
        user_id=job.recruiter_id,
        user_type="recruiter",
        title="Job Started",
        body=f"{current_tasker.full_name} has started working on: {job.title}",
        db=db
    )
    
    return {"message": "Job marked as started"}

@router.post("/{job_id}/request-completion")
async def request_job_completion(
    job_id: int,
    completion_note: Optional[str] = None,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Request recruiter to mark job as complete"""
    
    job = db.query(Job).filter_by(id=job_id, tasker_id=current_tasker.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found or not assigned to you")
    
    if job.status != JobStatus.IN_PROGRESS:
        raise HTTPException(400, "Job must be in progress")
    
    # Notify recruiter
    send_push(
        user_id=job.recruiter_id,
        user_type="recruiter",
        title="Job Completion Requested",
        body=f"{current_tasker.full_name} requests completion confirmation for: {job.title}",
        data={"job_id": job_id, "note": completion_note},
        db=db
    )
    
    return {"message": "Completion request sent to recruiter"}
