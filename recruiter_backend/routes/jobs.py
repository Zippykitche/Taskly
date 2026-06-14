from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus, JobApplication
from shared.models.user import Recruiter
from shared.models.pricing import ServicePricing
from recruiter_backend.routes.auth import get_current_recruiter
from shared.services.claude_ai import ClaudeAI
from shared.services.notifications import send_push
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/jobs", tags=["Jobs"])

class CreateJobRequest(BaseModel):
    title: str
    description: str
    category: str
    location_city: str
    location_area: str
    location_address: str
    urgency: str  # "normal", "urgent", "asap"

@router.post("/create")
async def create_job(
    job_data: CreateJobRequest,
    current_recruiter: Recruiter = Depends(get_current_recruiter),
    db: Session = Depends(get_db)
):
    """Create job with AI-calculated fair price"""
    
    print(f"📝 Creating job: {job_data.title}")
    
    # 1. Get complexity score from Claude
    print("🤖 Claude analyzing job complexity...")
    complexity = ClaudeAI.analyze_job_complexity(
        title=job_data.title,
        description=job_data.description,
        category=job_data.category,
        urgency=job_data.urgency
    )
    
    complexity_score = complexity["complexity_score"]
    print(f"✅ Complexity: {complexity_score}")
    
    # 2. Base prices by category
    base_prices = {
        "Plumbing": 1500,
        "Electrical": 2000,
        "Carpentry": 1800,
        "Cleaning": 1000,
        "Tutoring": 2500,
        "Nanny": 3000,
        "House Help": 1200,
        "Painting": 1600,
        "Gardening": 1400,
    }
    base_price = base_prices.get(job_data.category, 2000)
    
    # 3. Apply multipliers
    urgency_multiplier = {
        "normal": 1.0,
        "urgent": 1.3,
        "asap": 1.5
    }.get(job_data.urgency, 1.0)
    
    location_multiplier = 1.1  # Nairobi markup
    
    # 4. Calculate final price
    final_price = int(
        base_price * complexity_score * urgency_multiplier * location_multiplier
    )
    
    print(f"💰 Final price: {final_price} KES")
    
    # 5. Create job in database
    job = Job(
        recruiter_id=current_recruiter.id,
        title=job_data.title,
        description=job_data.description,
        category=job_data.category,
        location_city=job_data.location_city,
        location_area=job_data.location_area,
        location_address=job_data.location_address,
        price=final_price,
        complexity_score=complexity_score,
        urgency=job_data.urgency,
        status=JobStatus.OPEN
    )
    
    db.add(job)
    db.commit()
    db.refresh(job)
    
    # Update recruiter stats
    current_recruiter.jobs_posted += 1
    db.commit()
    
    print(f"✅ Job created with ID: {job.id}")
    
    return {
        "job_id": job.id,
        "title": job.title,
        "price": final_price,
        "complexity_score": complexity_score,
        "complexity_level": complexity["difficulty_level"],
        "reasoning": complexity["reasoning"],
        "status": "open",
        "created_at": job.created_at
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
    updates: CreateJobRequest,
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
