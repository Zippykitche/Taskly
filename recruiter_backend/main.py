from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from shared.models.database import get_db, User, Job, Application, WorkImage, Transaction
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
import jwt
import os
from datetime import datetime, timedelta

app = FastAPI(title="Taskly Recruiter Backend")

# ========== CONFIG ==========
SECRET_KEY = os.getenv("JWT_SECRET", "test_secret_key_taskly")
ALGORITHM = "HS256"

# ========== SCHEMAS ==========
class UserRegister(BaseModel):
    phone_number: str
    password: str
    full_name: str
    email: str
    location_city: str
    location_area: str

class JobCreate(BaseModel):
    title: str
    description: str
    category: str
    location_city: str
    location_area: str
    location_address: str
    urgency: str

class Token(BaseModel):
    access_token: str
    token_type: str

# ========== HELPER FUNCTIONS ==========
def create_access_token(data: dict, expires_delta=None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(hours=24)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        phone = payload.get("sub")
        if phone is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return phone
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

# ========== AUTH ROUTES ==========
@app.post("/auth/register")
async def register(user: UserRegister, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.phone_number == user.phone_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already exists")
    
    db_user = User(
        phone_number=user.phone_number,
        password=user.password,
        full_name=user.full_name,
        email=user.email,
        user_type="recruiter",
        location_city=user.location_city,
        location_area=user.location_area
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return {
        "user_id": db_user.phone_number,
        "full_name": db_user.full_name,
        "message": "Registration successful"
    }

@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone_number == form_data.username).first()
    if not user or user.password != form_data.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": form_data.username})
    return {"access_token": access_token, "token_type": "bearer"}

# ========== JOB ROUTES ==========
@app.post("/jobs/create")
async def create_job(job: JobCreate, current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    # Calculate price with Claude
    base_prices = {
        "Plumbing": 1500, "Electrical": 2000, "Carpentry": 1800,
        "Cleaning": 1000, "Tutoring": 2500, "Nanny": 3000
    }
    
    base_price = base_prices.get(job.category, 2000)
    urgency_multiplier = {"normal": 1.0, "urgent": 1.3, "asap": 1.5}.get(job.urgency, 1.0)
    final_price = int(base_price * urgency_multiplier)
    
    db_job = Job(
        title=job.title,
        description=job.description,
        category=job.category,
        location_city=job.location_city,
        location_area=job.location_area,
        location_address=job.location_address,
        urgency=job.urgency,
        price=final_price,
        recruiter_id=current_user
    )
    db.add(db_job)
    db.commit()
    db.refresh(db_job)
    
    return {
        "job_id": db_job.id,
        "title": db_job.title,
        "price": db_job.price,
        "message": "Job created"
    }

@app.get("/jobs/{job_id}/applications")
async def get_applications(job_id: int, current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    applications = db.query(Application).filter(Application.job_id == job_id).all()
    
    return {
        "job_id": job_id,
        "applications": [
            {
                "application_id": a.id,
                "tasker_id": a.tasker_id,
                "cover_letter": a.cover_letter,
                "status": a.status
            }
            for a in applications
        ],
        "total": len(applications)
    }

# ========== IMAGE ENDPOINTS ==========

@app.get("/jobs/{job_id}/images")
async def get_job_images(job_id: int, current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    """Recruiter can view work images"""
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    images = db.query(WorkImage).filter(WorkImage.job_id == job_id).all()
    
    return {
        "job_id": job_id,
        "images": [
            {
                "image_id": img.id,
                "image_url": img.image_url,
                "image_type": img.image_type,
                "uploaded_at": img.uploaded_at.isoformat()
            }
            for img in images
        ],
        "total": len(images)
    }

@app.post("/jobs/{job_id}/approve-work")
async def approve_work(job_id: int, current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    """Recruiter approves work (triggers payment release)"""
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return {
        "job_id": job_id,
        "status": "approved",
        "message": "Work approved. Payment will be released.",
        "amount": job.price
    }

# ========== HEALTH CHECK ==========
@app.get("/")
async def health():
    return {"status": "Recruiter Backend Running on 8003"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8003)
