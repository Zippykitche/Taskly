from datetime import datetime, timedelta
import os

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
import jwt
from pydantic import BaseModel
from sqlalchemy.orm import Session

from shared.database import Base, engine, get_db
from shared.models.db_models import Application, Dispute, Job, User, WorkImage
from shared.services.email_service import email_service
from shared.services.mpesa_service import mpesa_service

load_dotenv()

app = FastAPI(title="Taskly Recruiter Backend")

Base.metadata.create_all(bind=engine)

SECRET_KEY = os.getenv("JWT_SECRET", "test_secret_key_taskly")
ALGORITHM = "HS256"


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


class PaymentInitiate(BaseModel):
    phone_number: str | None = None


class DisputeCreate(BaseModel):
    reason: str
    description: str | None = None


class Token(BaseModel):
    access_token: str
    token_type: str


def create_access_token(data: dict, expires_delta=None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=24))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


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
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")


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
        location_city=user_data.location_city,
        location_area=user_data.location_area,
        user_type="recruiter",
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "user_id": new_user.phone_number,
        "full_name": new_user.full_name,
        "message": "Registration successful",
    }


@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone_number == form_data.username).first()
    if not user or user.password != form_data.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    access_token = create_access_token(data={"sub": form_data.username})
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/profile/me")
async def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "phone_number": current_user.phone_number,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "location_city": current_user.location_city,
        "location_area": current_user.location_area,
    }


@app.post("/jobs/create")
async def create_job(
    job_data: JobCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    base_prices = {
        "Plumbing": 1500,
        "Electrical": 2000,
        "Carpentry": 1800,
        "Cleaning": 1000,
        "Tutoring": 2500,
        "Nanny": 3000,
        "House Help": 1200,
        "Painting": 1600,
        "Gardening": 1400,
    }

    base_price = base_prices.get(job_data.category, 2000)
    urgency_multiplier = {"normal": 1.0, "urgent": 1.3, "asap": 1.5}.get(job_data.urgency, 1.0)
    final_price = int(base_price * urgency_multiplier)

    new_job = Job(
        title=job_data.title,
        description=job_data.description,
        category=job_data.category,
        location_city=job_data.location_city,
        location_area=job_data.location_area,
        location_address=job_data.location_address,
        urgency=job_data.urgency,
        price=final_price,
        recruiter_id=current_user.id,
        recruiter_phone=current_user.phone_number,
        status="open",
    )

    db.add(new_job)
    db.commit()
    db.refresh(new_job)

    return {
        "job_id": new_job.id,
        "title": new_job.title,
        "price": new_job.price,
        "status": "open",
        "created_at": new_job.created_at.isoformat(),
    }


@app.get("/jobs/{job_id}/applications")
async def get_applications(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    applications = db.query(Application).filter(Application.job_id == job_id).all()
    return {
        "job_id": job_id,
        "applications": [
            {
                "application_id": application.id,
                "tasker_id": application.tasker_id,
                "tasker_phone": application.tasker_phone,
                "cover_letter": application.cover_letter,
                "status": application.status,
                "created_at": application.created_at.isoformat(),
            }
            for application in applications
        ],
        "total": len(applications),
    }


@app.post("/applications/{app_id}/accept")
async def accept_application(
    app_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    application = db.query(Application).filter(Application.id == app_id).first()
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    application.status = "accepted"
    db.commit()

    return {"message": "Application accepted", "application_id": app_id}


@app.get("/jobs/{job_id}/images")
async def get_job_images(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    images = db.query(WorkImage).filter(WorkImage.job_id == job_id).all()
    return {
        "job_id": job_id,
        "images": [
            {
                "image_id": image.id,
                "image_url": image.image_url,
                "image_type": image.image_type,
                "uploaded_at": image.uploaded_at.isoformat(),
            }
            for image in images
        ],
        "total": len(images),
    }


@app.post("/jobs/{job_id}/approve-work")
async def approve_work(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    job.status = "approved"
    db.commit()

    return {
        "job_id": job_id,
        "status": "approved",
        "message": "Work approved. Payment will be released.",
        "amount": job.price,
    }


@app.post("/jobs/{job_id}/payments/initiate")
async def initiate_payment(
    job_id: int,
    payment_data: PaymentInitiate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.recruiter_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only pay for your own jobs")

    try:
        payment = await mpesa_service.initiate_job_payment(
            db=db,
            job=job,
            recruiter=current_user,
            phone_number=payment_data.phone_number,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return {
        "job_id": job_id,
        "amount": job.price,
        **payment,
    }


@app.post("/jobs/{job_id}/payments/release")
async def release_payment(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.recruiter_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only release payment for your own jobs")
    if job.status == "disputed":
        raise HTTPException(status_code=400, detail="Cannot release payment while job is disputed")

    try:
        release = mpesa_service.release_job_payment(db, job)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    tasker = db.query(User).filter(User.id == release["tasker_id"]).first()
    if tasker:
        email_service.send_payment_released(tasker.email, int(release["tasker_amount"]), job.title)

    return {
        "message": "Payment released",
        **release,
    }


@app.post("/jobs/{job_id}/disputes")
async def open_dispute(
    job_id: int,
    dispute_data: DisputeCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.recruiter_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only dispute your own jobs")

    existing = db.query(Dispute).filter(
        Dispute.job_id == job_id,
        Dispute.status == "open",
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="An open dispute already exists for this job")

    dispute = Dispute(
        job_id=job_id,
        opened_by_id=current_user.id,
        reason=dispute_data.reason,
        description=dispute_data.description,
        status="open",
    )
    job.status = "disputed"

    db.add(dispute)
    db.commit()
    db.refresh(dispute)

    application = db.query(Application).filter(
        Application.job_id == job_id,
        Application.status == "accepted",
    ).first()
    if application:
        tasker = db.query(User).filter(User.id == application.tasker_id).first()
        if tasker:
            email_service.send_dispute_opened(tasker.email, job.title, dispute.reason)

    return {
        "dispute_id": dispute.id,
        "job_id": job_id,
        "status": dispute.status,
        "message": "Dispute opened",
    }


@app.get("/disputes")
async def list_disputes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    disputes = (
        db.query(Dispute)
        .join(Job, Dispute.job_id == Job.id)
        .filter(Job.recruiter_id == current_user.id)
        .order_by(Dispute.created_at.desc())
        .all()
    )

    return {
        "total": len(disputes),
        "disputes": [
            {
                "dispute_id": dispute.id,
                "job_id": dispute.job_id,
                "reason": dispute.reason,
                "description": dispute.description,
                "status": dispute.status,
                "resolution": dispute.resolution,
                "created_at": dispute.created_at.isoformat(),
                "resolved_at": dispute.resolved_at.isoformat() if dispute.resolved_at else None,
            }
            for dispute in disputes
        ],
    }


@app.get("/jobs/{job_id}/disputes")
async def get_job_disputes(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.recruiter_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view disputes for your own jobs")

    disputes = (
        db.query(Dispute)
        .filter(Dispute.job_id == job_id)
        .order_by(Dispute.created_at.desc())
        .all()
    )
    return {
        "job_id": job_id,
        "total": len(disputes),
        "disputes": [
            {
                "dispute_id": dispute.id,
                "reason": dispute.reason,
                "description": dispute.description,
                "status": dispute.status,
                "resolution": dispute.resolution,
                "created_at": dispute.created_at.isoformat(),
                "resolved_at": dispute.resolved_at.isoformat() if dispute.resolved_at else None,
            }
            for dispute in disputes
        ],
    }


@app.get("/")
async def health():
    return {"status": "Recruiter Backend Running on 8003", "database": "PostgreSQL"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8003)
