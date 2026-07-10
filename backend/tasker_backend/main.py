import sys
import os
from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
import jwt

# Add project root to path to allow imports from shared
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import text
from dotenv import load_dotenv

# Import database stuff
from shared.database import get_db, engine, Base
from shared.models.db_models import User, Job, Application, WorkImage, Wallet, Transaction, Rating, Dispute

# Import services
from shared.services.image_verification import ImageVerification
from shared.services.email_service import EmailService
# from shared.services.mpesa_service import MpesaService
from shared.services.ratings_service import RatingsService

# At the TOP of file, after imports:
from shared.security.rate_limiter import rate_limiter, RateLimitConfig
from shared.security.password_security import PasswordSecurity, InputValidation
from shared.security.jwt_security import JWTSecurity
from shared.security.audit_logger import AuditLogger
from shared.security.secrets_manager import SecretsManager
from shared.security.cors_security import configure_cors

load_dotenv()

app = FastAPI(title="Taskly Tasker Backend")

# Base.metadata.create_all(bind=engine) # This is better handled by Alembic
# AFTER creating app = FastAPI(...):

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
image_verifier = ImageVerification()
# mpesa_service = MpesaService()

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

class UserLogin(BaseModel):
    username: str
    password: str

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
class AddRating(BaseModel):
    job_id: int
    ratee_id: int
    rating_value: int
    review: str = None

class WithdrawRequest(BaseModel):
    amount: float
    phone_number: str

class FiledDispute(BaseModel):
    reason: str
    description: str

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        payload = JWTSecurity.verify_token(token)
        phone = payload.get("sub")
        if phone is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        user = db.query(User).filter(User.phone_number == phone).first()
        user = db.query(User).filter(User.phone_number == phone, User.user_type == 'tasker').first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        
        return user
    except jwt.ExpiredSignatureError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

# Add rate limiting middleware
@app.middleware("http")
async def rate_limit_middleware_config(request: Request, call_next):
    from shared.security.rate_limiter import rate_limit_middleware
    return await rate_limit_middleware(request, call_next)

# ========== AUTH ROUTES ==========
@app.post("/auth/register")
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    try:
        # Validate input
        if not InputValidation.validate_email(user_data.email):
            raise HTTPException(status_code=400, detail="Invalid email")
        
        if not InputValidation.validate_phone(user_data.phone_number):
            raise HTTPException(status_code=400, detail="Invalid phone")
        
        # Validate password strength
        valid, message = PasswordSecurity.validate_password_strength(user_data.password)
        if not valid:
            raise HTTPException(status_code=400, detail=message)
        
        existing = db.query(User).filter(User.phone_number == user_data.phone_number).first()
        if existing:
            AuditLogger.log_event(
                event_type="REGISTER",
                user_email=user_data.email,
                status="FAILED",
                details={"reason": "User already exists"}
            )
            raise HTTPException(status_code=400, detail="User already exists")
        
        new_user = User(
            phone_number=user_data.phone_number,
            password=PasswordSecurity.hash_password(user_data.password),
            full_name=InputValidation.sanitize_string(user_data.full_name),
            email=user_data.email.lower(),
            id_number=user_data.id_number,
            categories=user_data.categories,
            location_city=user_data.location_city,
            location_area=user_data.location_area,
            user_type="tasker"
        )
        
        db.add(new_user)
        db.flush()
        

        # Create wallet
        # Create wallet for the new tasker
        wallet = Wallet(user_id=new_user.id)
        db.add(wallet)
        
        db.commit()
        db.refresh(new_user)
        

        # Log successful registration
        AuditLogger.log_event(
            event_type="REGISTER",
            user_id=new_user.id,
            user_email=new_user.email,
            status="SUCCESS"
        )

        # Send welcome email
        email_service.send_registration_email(
            to_email=new_user.email,
            full_name=new_user.full_name,
            user_type="tasker"
        )
        
        return {
            "user_id": new_user.id,
            "phone_number": new_user.phone_number,
            "full_name": new_user.full_name,
            "message": "Registration successful"
        }

        return {"user_id": new_user.id, "message": "Registration successful"}
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
        AuditLogger.log_event(
            event_type="REGISTER",
            status="ERROR",
            details={"error": str(e)}
        )
        raise HTTPException(status_code=500, detail="Registration error")

@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    try:
        user = db.query(User).filter(User.phone_number == form_data.username, User.user_type == 'tasker').first()

        if not user or not PasswordSecurity.verify_password(form_data.password, user.password):
            AuditLogger.log_event(
                event_type="FAILED_LOGIN",
                user_email=form_data.username,
                status="FAILED",
                details={"reason": "Invalid credentials"}
            )
            raise HTTPException(status_code=401, detail="Invalid credentials")

        access_token = JWTSecurity.create_access_token(data={"sub": form_data.username})

        AuditLogger.log_event(
            event_type="LOGIN",
            user_id=user.id,
            user_email=user.email,
            status="SUCCESS"
        )

        return {"access_token": access_token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        AuditLogger.log_event(
            event_type="LOGIN",
            status="ERROR",
            details={"error": str(e)}
        )
        raise HTTPException(status_code=500, detail="Login error")

# ========== JOB ROUTES ==========
@app.get("/jobs/browse")
async def browse_jobs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        jobs = db.query(Job).filter(Job.status == "open").all()
        jobs = db.query(Job).options(joinedload(Job.recruiter)).filter(Job.status == "open").all()
        return {
            "jobs": [
                {
                    "job_id": job.id,
                    "title": job.title,
                    "description": job.description,
                    "category": job.category,
                    "price": job.price,
                    "urgency": job.urgency,
                    "location": f"{job.location_city}, {job.location_area}",
                    "recruiter": job.recruiter.full_name if job.recruiter else "Unknown",
                    "created_at": job.created_at.isoformat()
                }
                for job in jobs
            ],
            "total": len(jobs)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/jobs/recommended")
async def recommend_jobs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        jobs = db.query(Job).filter(Job.status == "open").all()
        
        matching = []
        for job in jobs:
            if job.category in current_user.categories:
                matching.append({
                    "job_id": job.id,
                    "title": job.title,
                    "category": job.category,
                    "price": job.price,
                    "urgency": job.urgency,
                    "match_score": 0.95,
                    "location": f"{job.location_city}, {job.location_area}",
                    "recruiter": job.recruiter.full_name if job.recruiter else "Unknown"
                })
        
        return {
            "recommendations": matching,
            "total": len(matching)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/jobs/{job_id}/apply")
async def apply_for_job(job_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        
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
        
        # Send email to recruiter
        if job.recruiter:
            email_service.send_application_received_email(
                to_email=job.recruiter.email,
                recruiter_name=job.recruiter.full_name,
                tasker_name=current_user.full_name,
                job_title=job.title
            )
        
        return {
            "application_id": application.id,
            "job_id": job_id,
            "message": "Application submitted successfully",
            "status": "pending"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

# ========== IMAGE ROUTES ==========
@app.post("/jobs/{job_id}/upload-image")
async def upload_work_image(job_id: int, image_data: UploadImage, 
                           current_user: User = Depends(get_current_user), 
                           db: Session = Depends(get_db)):
    try:
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
            "image_type": image_data.image_type,
            "message": "Image uploaded successfully",
            "status": "success"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/jobs/{job_id}/images")
async def get_job_images(job_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
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
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ========== WORK VERIFICATION ROUTES ==========
@app.post("/jobs/{job_id}/verify-work")
async def verify_work_completion(job_id: int, verify_data: VerifyWork,
                                 current_user: User = Depends(get_current_user),
                                 db: Session = Depends(get_db)):
    try:
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        
        # Get images
        images = db.query(WorkImage).filter(WorkImage.job_id == job_id).all()
        before_image = next((img for img in images if img.image_type == "before"), None)
        after_image = next((img for img in images if img.image_type == "after"), None)
        
        # Verify work
        verification = image_verifier.verify_job_completion(
            job_category=job.category,
            before_image_url=before_image.image_url if before_image else None,
            after_image_url=after_image.image_url if after_image else None,
            both_parties_agree=verify_data.both_parties_agree
        )
        
        if verification["approved"]:
            # Update job status
            job.status = "completed"
            job.completed_at = datetime.utcnow()
            
            # Get recruiter and tasker
            recruiter = job.recruiter
            tasker = db.query(User).filter(User.id == job.tasker_id).first()
            
            if tasker:
                # Calculate payment: 85% to worker, 15% commission
                worker_amount = job.price * 0.85
                commission_amount = job.price * 0.15
                
                # Update wallet
                wallet = db.query(Wallet).filter(Wallet.user_id == tasker.id).first()
                if wallet:
                    wallet.balance += worker_amount
                    wallet.total_earned += worker_amount
                    wallet.available_withdrawal += worker_amount
                
                # Create transaction
                transaction = Transaction(
                    user_id=tasker.id,
                    amount=worker_amount,
                    type="payment",
                    job_id=job_id,
                    status="completed"
                )
                db.add(transaction)
                
                # Send payment email
                email_service.send_payment_released_email(
                    to_email=tasker.email,
                    tasker_name=tasker.full_name,
                    amount=worker_amount,
                    job_title=job.title
                )
            
            db.commit()
        
        return {
            "job_id": job_id,
            "approved": verification["approved"],
            "reason": verification["reason"],
            "method": verification["method"],
            "match_percentage": verification.get("match_percentage", 0),
            "status": "completed" if verification["approved"] else "pending_approval"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

# ========== RATING ROUTES ==========
@app.post("/jobs/{job_id}/rate")
async def rate_job(job_id: int, rating_data: AddRating,
                   current_user: User = Depends(get_current_user),
                   db: Session = Depends(get_db)):
    try:
        result = RatingsService.add_rating(
            db=db,
            job_id=job_id,
            rater_id=current_user.id,
            ratee_id=rating_data.ratee_id,
            rating_value=rating_data.rating_value,
            review=rating_data.review
        )
        
        if result["success"]:
            # Send email to ratee
            ratee = db.query(User).filter(User.id == rating_data.ratee_id).first()
            if ratee:
                email_service.send_rating_received_email(
                    to_email=ratee.email,
                    full_name=ratee.full_name,
                    user_type=ratee.user_type
                )
        
        return result
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error rating job: {e}")

@app.get("/profile/{user_id}/ratings")
async def get_user_ratings(user_id: int, db: Session = Depends(get_db)):
    try:
        return RatingsService.get_user_ratings(db=db, user_id=user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# ========== PROFILE ROUTES ==========
@app.get("/profile/me")
async def get_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        # Get rating summary
        rating_summary = RatingsService.get_rating_summary(db=db, user_id=current_user.id)
        
        return {
            "user_id": current_user.id,
            "phone_number": current_user.phone_number,
            "full_name": current_user.full_name,
            "email": current_user.email,
            "id_number": current_user.id_number,
            "categories": current_user.categories,
            "location_city": current_user.location_city,
            "location_area": current_user.location_area,
            "profile_picture": current_user.profile_picture_url,
            "rating": current_user.rating,
            "total_jobs": current_user.total_jobs,
            "total_ratings": rating_summary.get("total_ratings", 0),
            "created_at": current_user.created_at.isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ========== EARNINGS ROUTES ==========
@app.get("/earnings/wallet")
async def get_wallet(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
        
        if not wallet:
            # This should not happen if wallet is created on registration
            wallet = Wallet(user_id=current_user.id)
            db.add(wallet)
            db.commit()
        
        return {
            "balance": wallet.balance,
            "balance": wallet.available_balance,
            "available_withdrawal": wallet.available_withdrawal,
            "total_earned": wallet.total_earned,
            "currency": "KES",
            "updated_at": wallet.updated_at.isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/earnings/transactions")
async def get_transactions(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        transactions = (
            db.query(Transaction)
            .filter(Transaction.user_id == current_user.id)
            .order_by(Transaction.created_at.desc())
            .all()
        )

        return {
            "transactions": [
                {
                    "transaction_id": t.id,
                    "amount": t.amount,
                    "type": t.type,
                    "job_id": t.job_id,
                    "status": t.status,
                    "mpesa_reference": t.mpesa_receipt_number,
                    "created_at": t.created_at.isoformat()
                }
                for t in transactions
            ],
            "total": len(transactions)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/earnings/withdraw")
async def withdraw_earnings(withdraw_data: WithdrawRequest,
                           current_user: User = Depends(get_current_user),
                           db: Session = Depends(get_db)):
    try:
        # # Validate phone
        # if not mpesa_service.validate_phone(withdraw_data.phone_number):
        #     raise HTTPException(status_code=400, detail="Invalid phone number")
        
        # # Get wallet
        # wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id).first()
        # if not wallet or wallet.available_withdrawal < withdraw_data.amount:
        #     raise HTTPException(status_code=400, detail="Insufficient funds")
        
        # # Initiate B2C withdrawal
        # result = mpesa_service.process_b2c_withdrawal(
        #     phone_number=withdraw_data.phone_number,
        #     amount=withdraw_data.amount,
        #     worker_name=current_user.full_name
        # )
        
        # if result["success"]:
        #     # Create transaction
        #     transaction = Transaction(
        #         user_id=current_user.id,
        #         amount=withdraw_data.amount,
        #         type="withdrawal",
        #         status="pending",
        #         mpesa_reference=result.get("transaction_id")
        #     )
        #     db.add(transaction)
            
        #     # Update wallet
        #     wallet.available_withdrawal -= withdraw_data.amount
            
        #     db.commit()
            
        #     return {
        #         "success": True,
        #         "message": "Withdrawal initiated",
        #         "amount": withdraw_data.amount,
        #         "transaction_id": transaction.id,
        #         "mpesa_transaction": result.get("transaction_id")
        #     }
        # else:
        #     return {
        #         "success": False,
        #         "message": result.get("message", "Withdrawal failed")
        #     }
        raise HTTPException(status_code=501, detail="Mpesa service not implemented")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

# ========== DISPUTE ROUTES ==========
@app.post("/jobs/{job_id}/dispute")
async def file_dispute(job_id: int, dispute_data: FiledDispute,
                       current_user: User = Depends(get_current_user),
                       db: Session = Depends(get_db)):
    try:
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        
        dispute = Dispute(
            job_id=job_id,
            creator_id=current_user.id,
            reason=dispute_data.reason,
            description=dispute_data.description,
            status="open"
        )
        
        db.add(dispute)
        db.commit()
        db.refresh(dispute)
        
        # Send email to both parties
        if job.recruiter:
            email_service.send_dispute_filed_email(
                to_email=job.recruiter.email,
                user_name=job.recruiter.full_name,
                job_title=job.title,
                reason=dispute_data.reason
            )
        
        email_service.send_dispute_filed_email(
            to_email=current_user.email,
            user_name=current_user.full_name,
            job_title=job.title,
            reason=dispute_data.reason
        )
        
        return {
            "dispute_id": dispute.id,
            "job_id": job_id,
            "status": "open",
            "message": "Dispute filed successfully"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/disputes")
async def get_disputes(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        disputes = db.query(Dispute).filter(Dispute.creator_id == current_user.id).all()
        
        return {
            "disputes": [
                {
                    "dispute_id": d.id,
                    "job_id": d.job_id,
                    "reason": d.reason,
                    "status": d.status,
                    "created_at": d.created_at.isoformat(),
                    "resolved_at": d.resolved_at.isoformat() if d.resolved_at else None
                }
                for d in disputes
            ],
            "total": len(disputes)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ========== HEALTH CHECK ==========
@app.get("/")
async def health(db: Session = Depends(get_db)):
    try:
        # Test database connection
        db.execute(text("SELECT 1"))
        return {
            "status": "Tasker Backend Running on 8002",
            "database": "PostgreSQL Connected",
            "timestamp": datetime.utcnow().isoformat()
        }
    except:
        return {
            "status": "Tasker Backend Running on 8002",
            "database": "PostgreSQL Error",
            "timestamp": datetime.utcnow().isoformat()
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8002)
