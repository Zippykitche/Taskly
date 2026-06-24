from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
import jwt
import os
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from dotenv import load_dotenv

# Import database stuff
from shared.database import get_db, engine, Base
from shared.models.db_models import User, Job, Application, WorkImage, Wallet
from shared.services.email_service import email_service
from shared.services.ratings_service import ratings_service

load_dotenv()

app = FastAPI(title="Taskly Tasker Backend")

# Create all tables on startup
Base.metadata.create_all(bind=engine)

# ========== CONFIG ==========
SECRET_KEY = os.getenv("JWT_SECRET", "test_secret_key_taskly")
ALGORITHM = "HS256"

# ========== SCHEMAS ==========
class UserRegister(BaseModel):
    phone_number: str
    password: str
    full_name: str
    email: str
    id_number: str
    categories: list[str]
    location_city: str
    location_area: str

class Token(BaseModel):
    access_token: str
    token_type: str

class UploadImage(BaseModel):
    job_id: int
    image_type: str
    image_url: str
    cloudinary_id: str

class VerifyWork(BaseModel):
    job_id: int
    both_parties_agree: bool = False

class RatingCreate(BaseModel):
    score: int
    comment: str | None = None

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
        
        user = db.query(User).filter(User.phone_number == phone).first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

# ========== AUTH ROUTES ==========
@app.post("/auth/register")
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.phone_number == user_data.phone_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already exists")
    
    new_user = User(
        phone_number=user_data.phone_number,
        password=user_data.password,
        full_name=user_data.full_name,
        email=user_data.email,
        id_number=user_data.id_number,
        categories=user_data.categories,
        location_city=user_data.location_city,
        location_area=user_data.location_area,
        user_type="tasker"
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {
        "user_id": new_user.phone_number,
        "full_name": new_user.full_name,
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
@app.get("/jobs/browse")
async def browse_jobs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    jobs = db.query(Job).filter(Job.status == "open").all()
    return {
        "jobs": [
            {
                "job_id": job.id,
                "title": job.title,
                "category": job.category,
                "price": job.price,
                "urgency": job.urgency,
                "location": f"{job.location_city}, {job.location_area}",
                "created_at": job.created_at.isoformat()
            }
            for job in jobs
        ],
        "total": len(jobs)
    }

@app.get("/jobs/recommended")
async def recommend_jobs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Get jobs matching user's categories
    jobs = db.query(Job).filter(Job.status == "open").all()
    
    matching = []
    for job in jobs:
        if job.category in current_user.categories:
            matching.append({
                "job_id": job.id,
                "title": job.title,
                "category": job.category,
                "price": job.price,
                "match_score": 0.95,
                "location": f"{job.location_city}, {job.location_area}"
            })
    
    return {
        "recommendations": matching,
        "total": len(matching)
    }

@app.post("/jobs/{job_id}/apply")
async def apply_for_job(job_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    # Check if already applied
    existing = db.query(Application).filter(
        Application.job_id == job_id,
        Application.tasker_id == current_user.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already applied")
    
    application = Application(
        job_id=job_id,
        tasker_id=current_user.id,
        tasker_phone=current_user.phone_number,
        cover_letter="Interested in this job",
        status="pending"
    )
    
    db.add(application)
    db.commit()
    db.refresh(application)
    
    return {
        "application_id": application.id,
        "message": "Application submitted",
        "status": "pending"
    }

# ========== IMAGE ROUTES ==========
@app.post("/jobs/{job_id}/upload-image")
async def upload_work_image(job_id: int, image_data: UploadImage, 
                           current_user: User = Depends(get_current_user), 
                           db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    image = WorkImage(
        job_id=job_id,
        uploaded_by=current_user.phone_number,
        image_url=image_data.image_url,
        image_type=image_data.image_type,
        cloudinary_id=image_data.cloudinary_id
    )
    
    db.add(image)
    db.commit()
    db.refresh(image)
    
    return {
        "image_id": image.id,
        "job_id": job_id,
        "message": f"{image_data.image_type.capitalize()} image uploaded",
        "status": "success"
    }

@app.get("/jobs/{job_id}/images")
async def get_job_images(job_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    images = db.query(WorkImage).filter(WorkImage.job_id == job_id).all()
    
    return {
        "job_id": job_id,
        "images": [
            {
                "image_id": img.id,
                "type": img.image_type,
                "url": img.image_url,
                "uploaded_at": img.uploaded_at.isoformat()
            }
            for img in images
        ],
        "total": len(images)
    }

# ========== PROFILE ROUTES ==========
@app.get("/profile/me")
async def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "phone_number": current_user.phone_number,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "categories": current_user.categories,
        "location_city": current_user.location_city,
        "location_area": current_user.location_area,
        "rating": current_user.rating,
        "total_jobs": current_user.total_jobs
    }

# ========== RATING ROUTES ==========
@app.get("/ratings/me")
async def get_my_ratings(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    ratings = ratings_service.get_user_ratings(db, current_user.id)
    return {
        "average_rating": current_user.rating,
        "total": len(ratings),
        "ratings": [
            {
                "rating_id": rating.id,
                "job_id": rating.job_id,
                "rater_id": rating.rater_id,
                "score": rating.score,
                "comment": rating.comment,
                "created_at": rating.created_at.isoformat(),
            }
            for rating in ratings
        ],
    }

@app.post("/jobs/{job_id}/ratings")
async def rate_recruiter(
    job_id: int,
    rating_data: RatingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    application = db.query(Application).filter(
        Application.job_id == job_id,
        Application.tasker_id == current_user.id,
        Application.status == "accepted",
    ).first()
    if not application:
        raise HTTPException(status_code=403, detail="Only the accepted tasker can rate this job")

    try:
        rating = ratings_service.create_rating(
            db=db,
            job_id=job_id,
            rater_id=current_user.id,
            ratee_id=job.recruiter_id,
            score=rating_data.score,
            comment=rating_data.comment,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    recruiter = db.query(User).filter(User.id == job.recruiter_id).first()
    if recruiter:
        email_service.send_rating_received(recruiter.email, rating.score, job.title)

    return {
        "rating_id": rating.id,
        "job_id": job_id,
        "score": rating.score,
        "message": "Rating submitted",
    }

# ========== EARNINGS ROUTES ==========
@app.get("/earnings/wallet")
async def get_wallet(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
    
    if not wallet:
        wallet = Wallet(user_id=current_user.id)
        db.add(wallet)
        db.commit()
    
    return {
        "balance": wallet.balance,
        "currency": "KES",
        "available_withdrawal": wallet.available_withdrawal,
        "total_earned": wallet.total_earned
    }

@app.get("/earnings/transactions")
async def get_transactions(current_user: User = Depends(get_current_user)):
    return {
        "transactions": [],
        "total": 0
    }

# ========== HEALTH CHECK ==========
@app.get("/")
async def health():
    return {"status": "Tasker Backend Running on 8002", "database": "PostgreSQL"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8002)
