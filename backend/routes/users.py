from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta
from typing import List, Optional

import models
import schemas
import auth
from database import SessionLocal

router = APIRouter()

@router.post("/register", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user: schemas.UserCreate, db: Session = Depends(auth.get_db)):
    """Register a new client or tasker"""
    # Check if user exists
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create user with hashed password
    hashed_pw = auth.get_password_hash(user.password)
    new_user = models.User(
        name=user.name,
        email=user.email,
        password=hashed_pw,
        location=user.location,
        role=user.role,
        phone=user.phone,
        bio=user.bio,
        skills=user.skills,
        experience=user.experience,
        availability=user.availability,
        photo_url=user.photo_url
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(auth.get_db)):
    """Login to receive a JWT access token"""
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    
    if not user or not auth.verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(auth.get_current_user)):
    """Get current logged in user details"""
    return current_user

@router.get("/workers", response_model=List[schemas.UserResponse])
def list_all_workers(db: Session = Depends(auth.get_db)):
    """List all registered workers"""
    return db.query(models.User).filter(models.User.role == models.UserRole.worker).all()

@router.get("/workers/{worker_id}", response_model=schemas.UserResponse)
def get_worker_profile(worker_id: int, db: Session = Depends(auth.get_db)):
    """Get a specific worker's public profile"""
    worker = db.query(models.User).filter(
        models.User.id == worker_id, 
        models.User.role == models.UserRole.worker
    ).first()
    
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    return worker

@router.get("/workers/search", response_model=List[schemas.UserResponse])
def search_workers(
    skill: Optional[str] = None,
    location: Optional[str] = None,
    availability: Optional[str] = None,
    db: Session = Depends(auth.get_db)
):
    """Search for workers based on skill, location, and availability"""
    query = db.query(models.User).filter(models.User.role == models.UserRole.worker)
    
    if skill:
        query = query.filter(models.User.skills.ilike(f"%{skill}%"))
    
    if location:
        query = query.filter(models.User.location.ilike(f"%{location}%"))
        
    if availability:
        query = query.filter(models.User.availability.ilike(f"%{availability}%"))
        
    return query.all()

def calculate_profile_completeness(user: models.User) -> int:
    """Calculates a score based on how many worker profile fields are filled."""
    score = 0
    if user.bio: score += 1
    if user.skills: score += 1
    if user.experience: score += 1
    if user.availability: score += 1
    if user.photo_url: score += 1
    return score

@router.get("/workers/recommended", response_model=List[schemas.UserResponse])
def get_recommended_workers(
    recruiter_location: Optional[str] = None,
    db: Session = Depends(auth.get_db)
):
    """
    Get a list of recommended workers.
    Recommendations are based on profile completeness and optional location.
    """
    query = db.query(models.User).filter(models.User.role == models.UserRole.worker)

    if recruiter_location:
        # Simple partial match for location for Phase 1
        query = query.filter(models.User.location.ilike(f"%{recruiter_location}%"))
    
    workers = query.all()

    # Sort by profile completeness (descending)
    # For Phase 1, "most active" is omitted as it requires more complex tracking.
    # "Nearest location" is handled by the filter.
    workers.sort(key=lambda w: calculate_profile_completeness(w), reverse=True)

    return workers