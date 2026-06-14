from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
import jwt
import os
from datetime import datetime, timedelta

app = FastAPI(title="Taskly Tasker Backend")

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

# ========== DATABASE (In-Memory) ==========
users_db = {}

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

async def get_current_user(token: str = Depends(oauth2_scheme)):
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
async def register(user: UserRegister):
    if user.phone_number in users_db:
        raise HTTPException(status_code=400, detail="User already exists")
    
    users_db[user.phone_number] = {
        "phone_number": user.phone_number,
        "password": user.password,
        "full_name": user.full_name,
        "email": user.email,
        "id_number": user.id_number,
        "categories": user.categories,
        "location_city": user.location_city,
        "location_area": user.location_area,
        "created_at": datetime.utcnow().isoformat()
    }
    
    return {
        "user_id": user.phone_number,
        "full_name": user.full_name,
        "message": "Registration successful"
    }

@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = users_db.get(form_data.username)
    if not user or user["password"] != form_data.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": form_data.username})
    return {"access_token": access_token, "token_type": "bearer"}

# ========== JOB ROUTES ==========
jobs_db = {}
job_counter = 1

@app.get("/jobs/browse")
async def browse_jobs(current_user: str = Depends(get_current_user)):
    return {
        "jobs": list(jobs_db.values()),
        "total": len(jobs_db)
    }

@app.get("/jobs/recommended")
async def recommend_jobs(current_user: str = Depends(get_current_user)):
    user = users_db[current_user]
    user_categories = user.get("categories", [])
    
    # Simple recommendation: jobs matching user's categories
    matching_jobs = [
        job for job in jobs_db.values() 
        if job.get("category") in user_categories
    ]
    
    return {
        "recommendations": matching_jobs,
        "total": len(matching_jobs)
    }

@app.post("/jobs/{job_id}/apply")
async def apply_for_job(job_id: int, current_user: str = Depends(get_current_user)):
    if job_id not in jobs_db:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return {
        "message": "Application submitted",
        "job_id": job_id,
        "tasker": current_user
    }

# ========== PROFILE ROUTES ==========
@app.get("/profile/me")
async def get_profile(current_user: str = Depends(get_current_user)):
    user = users_db.get(current_user)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "phone_number": user["phone_number"],
        "full_name": user["full_name"],
        "email": user["email"],
        "categories": user["categories"],
        "location_city": user["location_city"],
        "location_area": user["location_area"]
    }

# ========== EARNINGS ROUTES ==========
@app.get("/earnings/wallet")
async def get_wallet(current_user: str = Depends(get_current_user)):
    return {
        "balance": 0,
        "currency": "KES",
        "available_withdrawal": 0
    }

@app.get("/earnings/transactions")
async def get_transactions(current_user: str = Depends(get_current_user)):
    return {
        "transactions": [],
        "total": 0
    }

# ========== HEALTH CHECK ==========
@app.get("/")
async def health():
    return {"status": "Tasker Backend Running on 8002"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8002)
