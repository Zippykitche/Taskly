from sqlalchemy import create_engine, Column, Integer, String, DateTime, Float, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
import os

# Database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./taskly.db")

# For PostgreSQL, it looks like:
# postgresql://user:password@localhost:5432/taskly_db

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ========== MODELS ==========

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, unique=True, index=True)
    password = Column(String)
    full_name = Column(String)
    email = Column(String)
    user_type = Column(String)  # "tasker" or "recruiter"
    id_number = Column(String, nullable=True)
    categories = Column(JSON, nullable=True)  # For taskers
    location_city = Column(String)
    location_area = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

class Job(Base):
    __tablename__ = "jobs"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(String)
    category = Column(String)
    location_city = Column(String)
    location_area = Column(String)
    location_address = Column(String)
    urgency = Column(String)  # normal, urgent, asap
    price = Column(Float)
    recruiter_id = Column(String)  # phone number
    status = Column(String, default="open")  # open, in_progress, completed
    created_at = Column(DateTime, default=datetime.utcnow)

class Application(Base):
    __tablename__ = "applications"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer)
    tasker_id = Column(String)  # phone number
    cover_letter = Column(String)
    status = Column(String, default="pending")  # pending, accepted, rejected
    created_at = Column(DateTime, default=datetime.utcnow)

class WorkImage(Base):
    __tablename__ = "work_images"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer)
    uploaded_by = Column(String)  # phone number
    image_url = Column(String)
    image_type = Column(String)  # before, after
    cloudinary_id = Column(String)
    uploaded_at = Column(DateTime, default=datetime.utcnow)

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer)
    tasker_id = Column(String)
    recruiter_id = Column(String)
    amount = Column(Float)
    status = Column(String)  # pending, completed, disputed
    created_at = Column(DateTime, default=datetime.utcnow)

# Create tables
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()