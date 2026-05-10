from pydantic import BaseModel, EmailStr
from typing import Optional, List
from models import UserRole, TaskStatus

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole
    phone: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: UserRole
    phone: str
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
    client_id: int
    tasker_id: Optional[int] = None
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