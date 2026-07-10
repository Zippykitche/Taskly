import sys
import os
from datetime import datetime

from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from pydantic import BaseModel
import jwt
from sqlalchemy.orm import Session
from sqlalchemy import text
from dotenv import load_dotenv

# Add project root to path to allow imports from shared
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Import database stuff
from shared.database import get_db, engine, Base
from shared.models.db_models import User, Job, Application, Transaction, Wallet, Dispute

# Import services
from shared.services.email_service import EmailService
from shared.services.mpesa_service import MpesaService
from shared.services.mpesa_callback import MpesaCallbackHandler

# Security Imports
from shared.security.rate_limiter import rate_limit_middleware
from shared.security.password_security import PasswordSecurity, InputValidation
from shared.security.jwt_security import JWTSecurity
from shared.security.audit_logger import AuditLogger
from shared.security.secrets_manager import SecretsManager
from shared.security.cors_security import configure_cors

load_dotenv()

app = FastAPI(title="Taskly Recruiter Backend")

# Validate secrets on startup
try:
    SecretsManager.validate_required_secrets()
except ValueError as e:
    print(f"⚠️  Security Warning: {str(e)}")

# Configure CORS security
configure_cors(app)

# ========== CONFIG ==========
SECRET_KEY = SecretsManager.get_secret("JWT_SECRET", "test_secret_key_taskly")
ALGORITHM = "HS256"

# Initialize services
email_service = EmailService()
mpesa_service = MpesaService()

# Base pricing
BASE_PRICES = {
    "Plumbing": 150000, # in cents
    "Electrical": 200000,
    "Carpentry": 180000,
    "Cleaning": 100000,
    "Tutoring": 250000,
    "Nanny": 300000,
    "House Help": 120000,
    "Painting": 160000,
    "Gardening": 140000
}

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

class InitiatePayment(BaseModel):
    phone_number: str

class ApproveApplication(BaseModel):
    pass

class ApproveWork(BaseModel):
    pass

class ResolveDispute(BaseModel):
    resolution: str
    refund_amount: float = 0
    
@app.middleware("http")
async def rate_limit_middleware_config(request: Request, call_next):
    return await rate_limit_middleware(request, call_next)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_recruiter(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Decodes the JWT token to get the current user, ensuring they are a recruiter.

    Args:
        token: The OAuth2 bearer token.
        db: The database session.

    Returns:
        The authenticated User object if they are a recruiter.
    """
    try:
        payload = JWTSecurity.verify_token(token)
        phone = payload.get("sub")
        if phone is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        user = db.query(User).filter(User.phone_number == phone, User.user_type == 'recruiter').first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))

# ========== AUTH ROUTES ==========
@app.post("/auth/register")
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """
    Registers a new recruiter user.

    Args:
        user_data: The registration data for the new user.
        db: The database session.

    Returns:
        A confirmation message with the new user's details.
    """
    try:
        if not InputValidation.validate_email(user_data.email):
            raise HTTPException(status_code=400, detail="Invalid email format")
        if not InputValidation.validate_phone(user_data.phone_number):
            raise HTTPException(status_code=400, detail="Invalid phone number format")

        user_data.phone_number = InputValidation.sanitize_string(user_data.phone_number)
        user_data.full_name = InputValidation.sanitize_string(user_data.full_name)
        user_data.location_city = InputValidation.sanitize_string(user_data.location_city)
        user_data.location_area = InputValidation.sanitize_string(user_data.location_area)

        valid, message = PasswordSecurity.validate_password_strength(user_data.password)
        if not valid:
            raise HTTPException(status_code=400, detail=message)

        existing = db.query(User).filter(User.phone_number == user_data.phone_number).first()
        if existing:
            AuditLogger.log_event(
                event_type="REGISTER", user_email=user_data.email, status="FAILED",
                details={"reason": "User already exists"}
            )
            raise HTTPException(status_code=400, detail="User with this phone number already exists")

        new_user = User(
            user_type='recruiter',
            phone_number=user_data.phone_number,
            password=PasswordSecurity.hash_password(user_data.password),
            full_name=InputValidation.sanitize_string(user_data.full_name),
            email=user_data.email.lower(),
            location_city=InputValidation.sanitize_string(user_data.location_city),
            location_area=InputValidation.sanitize_string(user_data.location_area),
        )
        
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        AuditLogger.log_event(
            event_type="REGISTER", user_id=new_user.id, user_email=new_user.email, status="SUCCESS"
        )
        
        # This method doesn't exist on the provided email_service
        # email_service.send_registration_email(
        #     to_email=new_user.email,
        #     full_name=new_user.full_name,
        #     user_type="recruiter"
        # )
        
        return {
            "user_id": new_user.id,
            "phone_number": new_user.phone_number,
            "full_name": new_user.full_name,
            "message": "Registration successful"
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        AuditLogger.log_event(event_type="REGISTER", status="ERROR", details={"error": str(e)})
        raise HTTPException(status_code=500, detail="An unexpected error occurred during registration.")

@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Authenticates a recruiter and returns a JWT access token.

    Args:
        form_data: The username (phone number) and password from the form.
        db: The database session.

    Returns:
        An access token and token type.
    """
    try:
        user = db.query(User).filter(User.phone_number == form_data.username, User.user_type == 'recruiter').first()
        
        if not user or not PasswordSecurity.verify_password(form_data.password, user.password):
            AuditLogger.log_event(
                event_type="FAILED_LOGIN", user_email=form_data.username, status="FAILED",
                details={"reason": "Invalid credentials"}
            )
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        access_token = JWTSecurity.create_access_token(data={"sub": form_data.username})
        
        AuditLogger.log_event(
            event_type="LOGIN", user_id=user.id, user_email=user.email, status="SUCCESS"
        )
        
        return {"access_token": access_token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        AuditLogger.log_event(event_type="LOGIN", status="ERROR", details={"error": str(e)})
        raise HTTPException(status_code=500, detail="An unexpected error occurred during login.")

# ========== JOB ROUTES ==========
@app.post("/jobs/create")
async def create_job(job_data: JobCreate, current_user: User = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    """
    Creates a new job posting for the authenticated recruiter.
    Calculates the job price based on category, urgency, and AI-driven complexity analysis.

    Args:
        job_data: The details of the job to create.
        current_user: The authenticated recruiter.
        db: The database session.

    Returns:
        The created job's details.
    """
    # Calculate price with urgency and AI complexity
    base_price = BASE_PRICES.get(job_data.category, 200000)
    urgency_multiplier = {"normal": 1.0, "urgent": 1.2, "asap": 1.4}.get(job_data.urgency, 1.0)
    
    # AI analysis for complexity
    complexity_analysis = ClaudeAI.analyze_job_complexity(
        title=job_data.title,
        description=job_data.description,
        category=job_data.category,
        urgency=job_data.urgency
    )
    complexity_multiplier = complexity_analysis.get("complexity_score", 1.0)

    final_price = int(base_price * urgency_multiplier * complexity_multiplier)
    
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
        status="open"
    )
    
    db.add(new_job)
    db.commit()
    db.refresh(new_job)
    
    # # Send email to recruiter - method does not exist on provided service
    # email_service.send_job_posted_email(
    #     to_email=current_user.email,
    #     recruiter_name=current_user.full_name,
    #     job_title=new_job.title,
    #     job_id=new_job.id
    # )
    
    return new_job.to_dict()

@app.get("/jobs/{job_id}/applications")
async def get_applications(job_id: int, current_user: User = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    """
    Retrieves all applications for a specific job owned by the recruiter.

    Args:
        job_id: The ID of the job.
        current_user: The authenticated recruiter.
        db: The database session.

    Returns:
        A list of applications for the job.
    """
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_user.id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found or unauthorized")
    
    applications = db.query(Application).filter(Application.job_id == job_id).all()
    
    return {
        "job_id": job_id,
        "job_title": job.title,
        "applications": [app.to_dict_recruiter() for app in applications],
        "total": len(applications)
    }

@app.post("/applications/{app_id}/accept")
async def accept_application(app_id: int, current_user: User = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    """
    Accepts a tasker's application for a job.
    Updates the job and application status, and assigns the tasker to the job.

    Args:
        app_id: The ID of the application to accept.
        current_user: The authenticated recruiter.
        db: The database session.

    Returns:
        A confirmation message.
    """
    app = db.query(Application).filter(Application.id == app_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    job = db.query(Job).filter(Job.id == app.job_id, Job.recruiter_id == current_user.id).first()
    if not job:
        raise HTTPException(status_code=403, detail="Unauthorized or Job not found")
    
    if job.status != "open":
        raise HTTPException(status_code=400, detail="Job is not open for applications")

    # Update application status
    app.status = "accepted"
    job.status = "assigned"
    job.tasker_id = app.tasker_id
    
    db.commit()
    
    return {
        "application_id": app_id,
        "status": "accepted",
        "message": "Application accepted. Tasker has been notified."
    }

# ========== PAYMENT ROUTES ==========
@app.post("/jobs/{job_id}/initiate-payment")
async def initiate_payment(job_id: int, payment_data: InitiatePayment,
                          current_user: User = Depends(get_current_recruiter),
                          db: Session = Depends(get_db)):
    """
    Initiates an M-Pesa STK push payment request for a job.

    Args:
        job_id: The ID of the job to pay for.
        payment_data: The phone number to send the STK push to.
        current_user: The authenticated recruiter.
        db: The database session.

    Returns:
        A confirmation message with the checkout request ID.
    """
    job = db.query(Job).filter(Job.id == job_id, Job.recruiter_id == current_user.id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found or unauthorized")
    
    # Initiate STK Push
    result = mpesa_service.initiate_stk_push(
        phone_number=payment_data.phone_number,
        amount=job.price, # amount is in cents
        job_id=job.id,
        job_title=job.title
    )
    
    if result["success"]:
        # Store checkout ID for later verification
        transaction = Transaction(
            job_id=job.id,
            recruiter_id=current_user.id,
            amount=job.price,
            status="pending",
            mpesa_transaction_id=result.get("CheckoutRequestID")
        )
        db.add(transaction)
        db.commit()
        
        return {
            "success": True,
            "message": "Payment prompt sent to customer phone",
            "checkout_request_id": result.get("CheckoutRequestID"),
            "amount": job.price / 100
        }
    else:
        raise HTTPException(status_code=500, detail=result.get("errorMessage", "Payment initiation failed"))

# ========== M-PESA CALLBACK ==========
@app.post("/mpesa/callback")
async def mpesa_callback(request: Request, db: Session = Depends(get_db)):
    """
    Handles the M-Pesa STK push callback for payment confirmation.

    Args:
        request: The incoming request from M-Pesa.
        db: The database session.

    Returns:
        The result from the callback handler.
    """
    callback_data = await request.json()
    handler = MpesaCallbackHandler(db)
    result = handler.handle_payment_callback(callback_data)
    return result

@app.post("/mpesa/withdrawal-callback")
async def mpesa_withdrawal_callback(request: Request, db: Session = Depends(get_db)):
    """
    Handles the M-Pesa B2C callback for withdrawal confirmation.

    Args:
        request: The incoming request from M-Pesa.
        db: The database session.

    Returns:
        The result from the callback handler.
    """
    callback_data = await request.json()
    handler = MpesaCallbackHandler(db)
    result = handler.handle_withdrawal_callback(callback_data)
    return result

# ========== PROFILE ROUTES ==========
@app.get("/profile/me")
async def get_profile(current_user: User = Depends(get_current_recruiter)):
    """
    Retrieves the profile of the currently authenticated recruiter.

    Args:
        current_user: The authenticated recruiter.

    Returns:
        The recruiter's profile information.
    """
    return current_user.to_dict()

# ========== ANALYTICS ROUTES ==========
@app.get("/jobs/stats")
async def get_job_stats(current_user: User = Depends(get_current_recruiter), db: Session = Depends(get_db)):
    """
    Retrieves statistics about jobs posted by the authenticated recruiter.

    Args:
        current_user: The authenticated recruiter.
        db: The database session.

    Returns:
        A dictionary of job statistics.
    """
    jobs = db.query(Job).filter(Job.recruiter_id == current_user.id).all()
    
    stats = {
        "total_jobs": len(jobs),
        "open_jobs": len([j for j in jobs if j.status == "open"]),
        "assigned_jobs": len([j for j in jobs if j.status == "assigned"]),
        "completed_jobs": len([j for j in jobs if j.status == "completed"]),
        "total_spent": sum([j.price for j in jobs if j.status == "completed"]) / 100
    }
    
    return stats

# ========== HEALTH CHECK ==========
@app.get("/")
async def health(db: Session = Depends(get_db)):
    """
    Health check endpoint to verify service and database status.

    Args:
        db: The database session.

    Returns:
        A status message indicating the health of the service.
    """
    try:
        # Test database connection
        db.execute(text("SELECT 1"))
        return {
            "status": "Recruiter Backend Running on 8003",
            "database": "PostgreSQL Connected",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8003)