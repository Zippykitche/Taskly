from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from shared.models.database import (
    get_db, User, Job, Application, WorkImage, Transaction
)
import jwt
import os
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel

app = FastAPI(title="Taskly Tasker Backend")

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

# ========== AUTH ==========
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

# ========== REGISTRATION ==========
@app.post("/auth/register")
async def register(user: UserRegister, db: Session = Depends(get_db)):
    # Check if user exists
    existing = db.query(User).filter(User.phone_number == user.phone_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already exists")
    
    # Create new user
    db_user = User(
        phone_number=user.phone_number,
        password=user.password,  # In production, hash this!
        full_name=user.full_name,
        email=user.email,
        user_type="tasker",
        id_number=user.id_number,
        categories=user.categories,
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

# ========== LOGIN ==========
@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone_number == form_data.username).first()
    if not user or user.password != form_data.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": form_data.username})
    return {"access_token": access_token, "token_type": "bearer"}

# ========== JOBS - BROWSE ==========
@app.get("/jobs/browse")
async def browse_jobs(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    jobs = db.query(Job).filter(Job.status == "open").all()
    return {
        "jobs": [
            {
                "job_id": j.id,
                "title": j.title,
                "category": j.category,
                "price": j.price,
                "location": f"{j.location_city}, {j.location_area}"
            }
            for j in jobs
        ],
        "total": len(jobs)
    }

# ========== JOBS - RECOMMENDATIONS ==========
@app.get("/jobs/recommended")
async def recommend_jobs(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone_number == current_user).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_categories = user.categories or []
    jobs = db.query(Job).filter(
        Job.status == "open",
        Job.category.in_(user_categories)
    ).all()
    
    return {
        "recommendations": [
            {
                "job_id": j.id,
                "title": j.title,
                "category": j.category,
                "price": j.price
            }
            for j in jobs
        ],
        "total": len(jobs)
    }

# ========== APPLICATIONS ==========
class ApplicationCreate(BaseModel):
    job_id: int
    cover_letter: str = "Interested in this job"

@app.post("/jobs/{job_id}/apply")
async def apply_for_job(job_id: int, app_data: ApplicationCreate, 
                       current_user: str = Depends(get_current_user), 
                       db: Session = Depends(get_db)):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    application = Application(
        job_id=job_id,
        tasker_id=current_user,
        cover_letter=app_data.cover_letter
    )
    db.add(application)
    db.commit()
    db.refresh(application)
    
    return {
        "application_id": application.id,
        "message": "Application submitted",
        "status": "pending"
    }

# ========== PROFILE ==========
@app.get("/profile/me")
async def get_profile(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone_number == current_user).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "phone_number": user.phone_number,
        "full_name": user.full_name,
        "email": user.email,
        "categories": user.categories,
        "location_city": user.location_city,
        "location_area": user.location_area
    }

# ========== WALLET ==========
@app.get("/earnings/wallet")
async def get_wallet(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    transactions = db.query(Transaction).filter(
        Transaction.tasker_id == current_user,
        Transaction.status == "completed"
    ).all()
    
    balance = sum(t.amount for t in transactions)
    
    return {
        "balance": balance,
        "currency": "KES",
        "available_withdrawal": balance
    }

@app.get("/earnings/transactions")
async def get_transactions(current_user: str = Depends(get_current_user), db: Session = Depends(get_db)):
    transactions = db.query(Transaction).filter(Transaction.tasker_id == current_user).all()
    
    return {
        "transactions": [
            {
                "transaction_id": t.id,
                "job_id": t.job_id,
                "amount": t.amount,
                "status": t.status,
                "created_at": t.created_at.isoformat()
            }
            for t in transactions
        ],
        "total": len(transactions)
    }

# ========== HEALTH ==========
@app.get("/")
async def health():
    return {"status": "Tasker Backend Running on 8002"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8002)
