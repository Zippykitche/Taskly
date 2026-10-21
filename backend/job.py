from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, JSON, Text, Enum
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import enum

Base = declarative_base()

class JobStatus(enum.Enum):
    OPEN = "open"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    DISPUTED = "disputed"

class Job(Base):
    __tablename__ = "jobs"
    
    id = Column(Integer, primary_key=True, index=True)
    recruiter_id = Column(Integer, nullable=False, index=True)
    tasker_id = Column(Integer, nullable=True, index=True)
    
    # Job details
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)
    subcategory = Column(String(50), nullable=True)
    
    # Location
    location_city = Column(String(50), nullable=False)
    location_area = Column(String(100), nullable=False)
    location_address = Column(String(200), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Pricing (in KES cents)
    price = Column(Integer, nullable=False)
    tasker_earnings = Column(Integer, nullable=False)
    platform_commission = Column(Integer, nullable=False)
    
    # AI Analysis
    complexity_score = Column(Float, nullable=True)
    ai_match_score = Column(Float, nullable=True)
    
    # Status & timing
    status = Column(Enum(JobStatus), default=JobStatus.OPEN)
    urgency = Column(String(20), default="normal")
    deadline = Column(DateTime, nullable=True)
    
    # Images
    images = Column(JSON, default=list)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    assigned_at = Column(DateTime, nullable=True)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    
    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "category": self.category,
            "location": {
                "city": self.location_city,
                "area": self.location_area,
                "address": self.location_address
            },
            "price": self.price / 100,
            "status": self.status.value,
            "urgency": self.urgency,
            "created_at": self.created_at.isoformat(),
            "images": self.images
        }

class JobApplication(Base):
    __tablename__ = "job_applications"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, nullable=False, index=True)
    tasker_id = Column(Integer, nullable=False, index=True)
    
    message = Column(Text, nullable=True)
    status = Column(String(20), default="pending")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    responded_at = Column(DateTime, nullable=True)

class Rating(Base):
    __tablename__ = "ratings"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, nullable=False, index=True)
    tasker_id = Column(Integer, nullable=False, index=True)
    recruiter_id = Column(Integer, nullable=False, index=True)
    
    stars = Column(Integer, nullable=False)
    review = Column(Text, nullable=True)
    ai_sentiment = Column(String(20), nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)