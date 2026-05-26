from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.user import Tasker, Wallet
from shared.models.job import Job, JobStatus
from shared.auth import get_current_tasker
from shared.services.cloudinary_service import upload_profile_image, upload_id_image
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter(prefix="/profile", tags=["Profile"])

class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    bio: Optional[str] = None
    categories: Optional[List[str]] = None
    location_city: Optional[str] = None
    location_area: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

@router.get("/me")
async def get_profile(
    current_tasker: Tasker = Depends(get_current_tasker)
):
    """Get current tasker's profile"""
    return current_tasker.to_dict()

@router.put("/me")
async def update_profile(
    updates: ProfileUpdate,
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Update tasker profile"""
    
    if updates.full_name:
        current_tasker.full_name = updates.full_name
    
    if updates.email:
        # Check if email already exists
        existing = db.query(Tasker).filter(
            Tasker.email == updates.email,
            Tasker.id != current_tasker.id
        ).first()
        
        if existing:
            raise HTTPException(400, "Email already in use")
        
        current_tasker.email = updates.email
    
    if updates.bio:
        current_tasker.bio = updates.bio
    
    if updates.categories:
        current_tasker.categories = updates.categories
    
    if updates.location_city:
        current_tasker.location_city = updates.location_city
    
    if updates.location_area:
        current_tasker.location_area = updates.location_area
    
    if updates.latitude:
        current_tasker.latitude = updates.latitude
    
    if updates.longitude:
        current_tasker.longitude = updates.longitude
    
    db.commit()
    db.refresh(current_tasker)
    
    return {
        "message": "Profile updated successfully",
        "profile": current_tasker.to_dict()
    }

@router.post("/upload-profile-image")
async def upload_profile_pic(
    file: UploadFile = File(...),
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Upload profile picture"""
    
    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")
    
    try:
        # Upload to Cloudinary
        image_url = await upload_profile_image(
            file=file,
            user_type="tasker",
            user_id=current_tasker.id
        )
        
        # Save URL to database
        current_tasker.profile_image_url = image_url
        db.commit()
        
        return {
            "message": "Profile image uploaded successfully",
            "image_url": image_url
        }
    
    except Exception as e:
        raise HTTPException(500, f"Upload failed: {str(e)}")

@router.post("/upload-id-image")
async def upload_id_verification(
    file: UploadFile = File(...),
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Upload ID for verification"""
    
    if not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")
    
    try:
        # Upload to Cloudinary
        image_url = await upload_id_image(
            file=file,
            tasker_id=current_tasker.id
        )
        
        # Save URL and mark as pending verification
        current_tasker.id_image_url = image_url
        current_tasker.verification_status = "pending"
        db.commit()
        
        return {
            "message": "ID uploaded successfully. Verification pending.",
            "image_url": image_url
        }
    
    except Exception as e:
        raise HTTPException(500, f"Upload failed: {str(e)}")

@router.get("/stats")
async def get_profile_stats(
    current_tasker: Tasker = Depends(get_current_tasker),
    db: Session = Depends(get_db)
):
    """Get tasker statistics"""
    
    # Job stats
    completed_jobs = db.query(Job).filter_by(
        tasker_id=current_tasker.id,
        status=JobStatus.COMPLETED
    ).count()
    
    active_jobs = db.query(Job).filter(
        Job.tasker_id == current_tasker.id,
        Job.status.in_([JobStatus.ASSIGNED, JobStatus.IN_PROGRESS])
    ).count()
    
    # Wallet
    wallet = db.query(Wallet).filter_by(tasker_id=current_tasker.id).first()
    
    return {
        "rating": current_tasker.rating,
        "jobs_completed": completed_jobs,
        "active_jobs": active_jobs,
        "total_earned": wallet.total_earned / 100 if wallet else 0,
        "verification_status": current_tasker.verification_status,
        "id_verified": current_tasker.id_verified
    }
