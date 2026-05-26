from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.job import Job, JobStatus
from shared.models.transaction import Transaction, TransactionStatus
from shared.models.pricing import ServicePricing
from shared.services.earl_ai import EARLAIClient
from recruiter_backend.routes.auth import get_current_recruiter
from shared.models.user import Recruiter

router = APIRouter()


earl_client = EARLAIClient()


class JobCreate(BaseModel):
    title: str
    description: str
    category: str
    subcategory: str | None = None
    location_city: str
    location_area: str
    location_address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    urgency: str = "normal"
    deadline: str | None = None
    images: list[str] | None = []


@router.post("/")
async def create_job(payload: JobCreate, current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    pricing = db.query(ServicePricing).filter(ServicePricing.category == payload.category).first()
    if not pricing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pricing configuration not found for this category")
    complexity = await earl_client.analyze_job_complexity(payload.description, payload.category, payload.urgency, f"{payload.location_city}, {payload.location_area}")
    complexity = max(pricing.min_complexity, min(pricing.max_complexity, complexity))
    location_multiplier = pricing.location_multiplier.get(payload.location_city, 1.0)
    urgency_multiplier = pricing.urgency_multiplier.get(payload.urgency, 1.0)
    total_price = int(pricing.base_price * location_multiplier * urgency_multiplier * complexity)
    commission = int(total_price * pricing.commission_rate)
    tasker_earnings = total_price - commission

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
        urgency=payload.urgency,
        deadline=datetime.fromisoformat(payload.deadline) if payload.deadline else None,
        price=total_price,
        tasker_earnings=tasker_earnings,
        platform_commission=commission,
        complexity_score=complexity,
        images=payload.images or [],
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job.to_dict()


@router.get("/")
def list_recruiter_jobs(current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    jobs = db.query(Job).filter(Job.recruiter_id == current_recruiter.id).all()
    return [job.to_dict() for job in jobs]


@router.get("/open")
def list_open_jobs(db: Session = Depends(get_db)):
    jobs = db.query(Job).filter(Job.status == JobStatus.OPEN).all()
    return [job.to_dict() for job in jobs]


@router.post("/{job_id}/reserve")
def reserve_job(job_id: int, current_recruiter: Recruiter = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_recruiter.id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    transaction = Transaction(
        job_id=job.id,
        recruiter_id=current_recruiter.id,
        tasker_id=job.tasker_id or 0,
        total_amount=job.price,
        tasker_amount=job.tasker_earnings,
        platform_commission=job.platform_commission,
        status=TransactionStatus.PENDING,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return transaction.to_dict()
