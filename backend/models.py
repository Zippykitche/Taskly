from sqlalchemy import Column, Integer, String, ForeignKey, Enum as SQLEnum, Date, DateTime, Boolean
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime, date
import enum

class UserRole(str, enum.Enum):
    recruiter = "recruiter"
    worker = "worker"

class TaskStatus(str, enum.Enum):
    posted = "posted"
    assigned = "assigned"
    in_progress = "in_progress"
    completed = "completed"

class BookingStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    role = Column(SQLEnum(UserRole))
    location = Column(String, nullable=True)
    phone = Column(String)
    # Worker Profile Fields
    bio = Column(String, nullable=True)
    skills = Column(String, nullable=True)  # Simple comma-separated for Phase 1
    experience = Column(String, nullable=True)
    availability = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)

class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(String)
    price = Column(Integer)
    location = Column(String)
    status = Column(SQLEnum(TaskStatus), default=TaskStatus.posted)
    recruiter_id = Column(Integer, ForeignKey("users.id"))
    worker_id = Column(Integer, ForeignKey("users.id"), nullable=True)

class Booking(Base):
    __tablename__ = "bookings"
    id = Column(Integer, primary_key=True, index=True)
    recruiter_id = Column(Integer, ForeignKey("users.id"))
    worker_id = Column(Integer, ForeignKey("users.id")) # Specific worker for direct booking
    title = Column(String)
    description = Column(String)
    location = Column(String)
    date = Column(Date)
    time = Column(String) # Store as string for flexibility (e.g., "9:00 AM", "Evening")
    status = Column(SQLEnum(BookingStatus), default=BookingStatus.pending)
    created_at = Column(DateTime, default=datetime.utcnow)

class Notification(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    message = Column(String)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Integer)
    phone = Column(String)
    checkout_request_id = Column(String, unique=True, index=True) # From Safaricom
    merchant_request_id = Column(String)
    receipt_number = Column(String, nullable=True) # Only populated after success
    status = Column(String, default="pending") # pending, success, failed
    created_at = Column(DateTime, default=datetime.utcnow)

class Review(Base):
    __tablename__ = "reviews"
    id = Column(Integer, primary_key=True, index=True)
    rating = Column(Integer)
    comment = Column(String)
    task_id = Column(Integer, ForeignKey("tasks.id"))
    reviewer_id = Column(Integer, ForeignKey("users.id"))