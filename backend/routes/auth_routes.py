from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from typing import List, Optional
from database import get_db
from models.tasker import Tasker, Wallet
from auth.auth_handler import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_tasker
)
from datetime import datetime

router = APIRouter(prefix="/auth", tags=["Authentication"])

class TaskerRegister(BaseModel):
    phone_number: str = Field(..., pattern=r"^254\d{9}$")
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2, max_length=100)
    email: Optional[str] = None
    id_number: str = Field(..., min_length=6, max_length=20)
    categories: List[str] = Field(..., min_items=1)
    location_city: str
    location_area: str

@router.post("/register")
async def register_tasker(tasker_data: TaskerRegister, db: Session = Depends(get_db)):
    # Check if phone exists
    existing = db.query(Tasker).filter(
        Tasker.phone_number == tasker_data.phone_number
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Phone number already registered"
        )
    
    # Check if ID number exists
    existing_id = db.query(Tasker).filter(
        Tasker.id_number == tasker_data.id_number
    ).first()
    
    if existing_id:
        raise HTTPException(
            status_code=400,
            detail="ID number already registered"
        )
    
    # Create tasker
    tasker = Tasker(
        phone_number=tasker_data.phone_number,
        hashed_password=hash_password(tasker_data.password),
        full_name=tasker_data.full_name,
        email=tasker_data.email,
        id_number=tasker_data.id_number,
        categories=tasker_data.categories,
        location_city=tasker_data.location_city,
        location_area=tasker_data.location_area
    )
    
    db.add(tasker)
    db.flush()  # Get tasker.id
    
    # Create wallet
    wallet = Wallet(tasker_id=tasker.id)
    db.add(wallet)
    
    db.commit()
    db.refresh(tasker)
    
    return {
        "message": "Registration successful",
        "tasker_id": tasker.id,
        "phone_number": tasker.phone_number
    }

@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    tasker = db.query(Tasker).filter(
        Tasker.phone_number == form_data.username
    ).first()
    
    if not tasker or not verify_password(form_data.password, tasker.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login
    tasker.last_login = datetime.utcnow()
    db.commit()
    
    # Create token
    access_token = create_access_token(data={"sub": tasker.phone_number})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": tasker.to_dict()
    }

@router.get("/me")
async def get_current_user(current_tasker: Tasker = Depends(get_current_tasker)):
    return current_tasker.to_dict()