from fastapi import FastAPI, Depends, HTTPException
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

# ========== DATABASE (In-Memory) ==========
users_db = {}
jobs_db = {}
job_counter = 1

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
@app.post("/jobs/create")
async def create_job(job: JobCreate, current_user: str = Depends(get_current_user)):
    global job_counter
    
    # Simple pricing (later we'll use Claude)
    base_prices = {
        "Plumbing": 1500,
        "Electrical": 2000,
        "Carpentry": 1800,
        "Cleaning": 1000,
        "Tutoring": 2500,
        "Nanny": 3000,
        "House Help": 1200,
        "Painting": 1600,
        "Gardening": 1400
    }
    
    base_price = base_prices.get(job.category, 2000)
    urgency_multiplier = {"normal": 1.0, "urgent": 1.3, "asap": 1.5}.get(job.urgency, 1.0)
    final_price = int(base_price * urgency_multiplier)
    
    job_id = job_counter
    jobs_db[job_id] = {
        "job_id": job_id,
        "title": job.title,
        "description": job.description,
        "category": job.category,
        "location_city": job.location_city,
        "location_area": job.location_area,
        "location_address": job.location_address,
        "urgency": job.urgency,
        "price": final_price,
        "recruiter": current_user,
        "created_at": datetime.utcnow().isoformat(),
        "status": "open"
    }
    job_counter += 1
    
    return jobs_db[job_id]

@app.get("/jobs/{job_id}/applications")
async def get_applications(job_id: int, current_user: str = Depends(get_current_user)):
    if job_id not in jobs_db:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return {
        "job_id": job_id,
        "applications": [],
        "total": 0
    }

# ========== HEALTH CHECK ==========
@app.get("/")
async def health():
    return {"status": "Recruiter Backend Running on 8003"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8003)
