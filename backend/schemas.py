from pydantic import BaseModel
from typing import Optional

class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    role: str
    phone: str

class UserLogin(BaseModel):
    email: str
    password: str

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
    status: str

    class Config:
        from_attributes = True

class ReviewCreate(BaseModel):
    rating: int
    comment: str
    task_id: int