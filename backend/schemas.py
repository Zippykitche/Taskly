from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import date, datetime
from enum import Enum

class UserRole(str, Enum):
    TASKER = "tasker"
    RECRUITER = "recruiter"

class TaskStatus(str, Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class BookingStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    COMPLETED = "completed"
    DISPUTED = "disputed"

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole
    phone: str
    location: Optional[str] = None
    bio: Optional[str] = None
    skills: Optional[str] = None
    experience: Optional[str] = None
    availability: Optional[str] = None
    photo_url: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: UserRole
    location: Optional[str] = None
    phone: str
    bio: Optional[str] = None
    skills: Optional[str] = None
    experience: Optional[str] = None
    availability: Optional[str] = None
    photo_url: Optional[str] = None
    class Config:
        from_attributes = True

class TaskCreate(BaseModel):
    title: str
    description: str
    price: int
    location: str

class TaskResponse(BaseModel):
    id: int
    title: str
    description: str
    price: int
    location: str
    status: TaskStatus
    recruiter_id: int
    worker_id: Optional[int] = None
    class Config:
        from_attributes = True

class BookingCreate(BaseModel):
    worker_id: int
    title: str
    description: str
    location: str
    date: date
    time: str

class BookingResponse(BaseModel):
    id: int
    recruiter_id: int
    worker_id: int
    title: str
    description: str
    location: str
    date: date
    time: str
    status: BookingStatus
    created_at: datetime
    class Config:
        from_attributes = True

class StkPushRequest(BaseModel):
    booking_id: int
    amount: int
    phone: str = Field(..., description="Phone number in format 2547XXXXXXXX")

class NotificationResponse(BaseModel):
    id: int
    message: str
    is_read: bool
    created_at: datetime
    class Config:
        from_attributes = True

class ReviewCreate(BaseModel):
    task_id: int
    rating: int
    comment: str

class ReviewResponse(BaseModel):
    id: int
    rating: int
    comment: str
    task_id: int
    reviewer_id: int
    class Config:
        from_attributes = True