from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus, JobApplication
from shared.models.user import Recruiter
from shared.models.pricing import ServicePricing
from shared.auth import get_current_recruiter
from shared.services.earl_ai import earl_client
from shared.services.notifications import send_push
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/jobs", tags=["Jobs"])

class JobCreate(BaseModel):
    title: str
    description: str
    category: str
    subcategory: Optional[str] = None
    location_city: str
    location_area: str
    location_address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    urgency: str = "normal"
    deadline: Optional[str] = None
    images: Optional[List[str]] = None

@router.post("/create")
async def create_job(
    payload: JobCreate,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Create a new job posting"""
    
    # Get pricing for category
    pricing = db.query(ServicePricing).filter_by(category=payload.category).first()
    
    if not pricing:
        raise HTTPException(400, f"No pricing configured for category: {payload.category}")
    
    # Analyze job complexity using E.A.R.L
    try:
        complexity = await earl_client.analyze_job_complexity(
            description=payload.description,
            category=payload.category,
            urgency=payload.urgency,
            location=f"{payload.location_city}, {payload.location_area}"
        )
    except Exception as e:
        complexity = 1.5  # Default to middle value
    
    # Ensure complexity is within bounds
    complexity = max(pricing.min_complexity, min(pricing.max_complexity, complexity))
    
    # Calculate price with multipliers
    location_multiplier = pricing.location_multiplier.get(payload.location_city, 1.0) if pricing.location_multiplier else 1.0
    urgency_multiplier = pricing.urgency_multiplier.get(payload.urgency, 1.0) if pricing.urgency_multiplier else 1.0
    
    total_price = int(pricing.base_price * location_multiplier * urgency_multiplier * complexity)
    commission = int(total_price * pricing.commission_rate)
    tasker_earnings = total_price - commission
    
    # Create job
    job = Job(
        recruiter_id=current_recruiter.id,
        title=payload.title,
        description=payload.description,
        category=payload.category,
        subcategory=payload.subcategory,
        location_city=payload.location_city,
        location_area=payload.location_area,
        location_address=payload.location_address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        price=total_price,
        tasker_earnings=tasker_earnings,
        platform_commission=commission,
        complexity_score=complexity,
        urgency=payload.urgency,
        deadline=datetime.fromisoformat(payload.deadline) if payload.deadline else None,
        images=payload.images or [],
        status=JobStatus.OPEN
    )
    
    db.add(job)
    db.commit()
    db.refresh(job)
    
    # Update recruiter stats
    current_recruiter.jobs_posted += 1
    db.commit()
    
    return {
        "message": "Job created successfully",
        "job": job.to_dict()
    }

@router.get("/my/jobs")
async def get_my_jobs(
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 20,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Get recruiter's job postings"""
    
    query = db.query(Job).filter_by(recruiter_id=current_recruiter.id)
    
    if status:
        try:
            status_enum = JobStatus[status.upper()]
            query = query.filter_by(status=status_enum)
        except KeyError:
            pass  # Invalid status, ignore
    
    jobs = query.order_by(Job.created_at.desc()).offset(skip).limit(limit).all()
    total = query.count()
    
    return {
        "jobs": [job.to_dict() for job in jobs],
        "total": total
    }

@router.get("/{job_id}")
async def get_job_details(
    job_id: int,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Get detailed job information"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    # Get applications
    applications = db.query(JobApplication).filter_by(job_id=job_id).all()
    
    return {
        "job": job.to_dict(),
        "applications_count": len(applications)
    }

@router.put("/{job_id}")
async def update_job(
    job_id: int,
    updates: JobCreate,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Update job details (only if still open)"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status != JobStatus.OPEN:
        raise HTTPException(400, "Cannot edit job that is not open")
    
    # Update fields
    job.title = updates.title
    job.description = updates.description
    job.location_address = updates.location_address
    job.urgency = updates.urgency
    
    if updates.deadline:
        job.deadline = datetime.fromisoformat(updates.deadline)
    
    db.commit()
    db.refresh(job)
    
    return {
        "message": "Job updated successfully",
        "job": job.to_dict()
    }

@router.post("/{job_id}/close")
async def close_job(
    job_id: int,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Close job posting"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    if job.status != JobStatus.OPEN:
        raise HTTPException(400, "Only open jobs can be closed")
    
    job.status = JobStatus.CANCELLED
    db.commit()
    
    return {"message": "Job closed successfully"}

@router.get("/{job_id}/applications")
async def get_job_applications(
    job_id: int,
    status: Optional[str] = None,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Get applications for a job"""
    
    job = db.query(Job).filter_by(id=job_id, recruiter_id=current_recruiter.id).first()
    
    if not job:
        raise HTTPException(404, "Job not found")
    
    query = db.query(JobApplication).filter_by(job_id=job_id)
    
    if status:
        query = query.filter_by(status=status)
    
    applications = query.order_by(JobApplication.created_at.desc()).all()
    
    result = []
    for app in applications:
        from shared.models.user import Tasker
        tasker = db.query(Tasker).filter_by(id=app.tasker_id).first()
        result.append({
            "application_id": app.id,
            "tasker": tasker.to_dict() if tasker else None,
            "message": app.message,
            "status": app.status,
            "applied_at": app.created_at.isoformat()
        })
    
    return {"applications": result}
