from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, JSON, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class Tasker(Base):
    __tablename__ = "taskers"
    
    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String(15), unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=True)
    id_number = Column(String(20), unique=True, nullable=False)
    
    # Profile
    bio = Column(Text, nullable=True)
    profile_image = Column(String, nullable=True)
    categories = Column(JSON, default=list)
    
    # Location
    location_city = Column(String(50), nullable=True)
    location_area = Column(String(100), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Verification
    phone_verified = Column(Boolean, default=False)
    verification_status = Column(String(20), default="pending")
    
    # Stats
    rating = Column(Float, default=0.0)
    jobs_completed = Column(Integer, default=0)
    active_jobs_count = Column(Integer, default=0)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    def to_dict(self):
        return {
            "id": self.id,
            "phone_number": self.phone_number,
            "full_name": self.full_name,
            "email": self.email,
            "categories": self.categories,
            "location": {
                "city": self.location_city,
                "area": self.location_area,
                "lat": self.latitude,
                "lng": self.longitude
            },
            "rating": self.rating,
            "jobs_completed": self.jobs_completed,
            "verification_status": self.verification_status,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class Wallet(Base):
    __tablename__ = "wallets"
    
    id = Column(Integer, primary_key=True, index=True)
    tasker_id = Column(Integer, unique=True, nullable=False)
    
    available_balance = Column(Integer, default=0)
    pending_balance = Column(Integer, default=0)
    pending_withdrawals = Column(Integer, default=0)
    
    total_earned = Column(Integer, default=0)
    total_withdrawn = Column(Integer, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)