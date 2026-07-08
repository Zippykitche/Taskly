import os
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from dotenv import load_dotenv
from shared.database import get_db
from shared.models.user import Recruiter

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

SECRET_KEY = os.getenv("SECRET_KEY", "recruiter-secret-key")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

router = APIRouter()


class RecruiterCreate(BaseModel):
    phone_number: str
    password: str
    full_name: str
    company_name: str | None = None
    email: Optional[EmailStr] = None


class RecruiterOut(BaseModel):
    id: int
    phone_number: str
    full_name: str
    email: Optional[EmailStr] = None
    company_name: str | None = None


class Token(BaseModel):
    access_token: str
    token_type: str


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_recruiter_by_phone(db: Session, phone: str):
    return db.query(Recruiter).filter(Recruiter.phone_number == phone).first()


def get_recruiter(db: Session, recruiter_id: int):
    return db.query(Recruiter).filter(Recruiter.id == recruiter_id).first()


def authenticate_recruiter(db: Session, phone: str, password: str):
    recruiter = get_recruiter_by_phone(db, phone)
    if not recruiter or not verify_password(password, recruiter.hashed_password):
        return None
    return recruiter


async def get_current_recruiter(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        recruiter_id: int = int(payload.get("sub"))
        if recruiter_id is None:
            raise credentials_exception
    except (JWTError, ValueError):
        raise credentials_exception
    recruiter = get_recruiter(db, recruiter_id)
    if recruiter is None:
        raise credentials_exception
    return recruiter


@router.post("/register", response_model=RecruiterOut)
def register(recruiter_in: RecruiterCreate, db: Session = Depends(get_db)):
    if get_recruiter_by_phone(db, recruiter_in.phone_number):
        raise HTTPException(status_code=400, detail="Phone number already registered")
    if recruiter_in.email and db.query(Recruiter).filter(Recruiter.email == recruiter_in.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    recruiter = Recruiter(
        phone_number=recruiter_in.phone_number,
        hashed_password=get_password_hash(recruiter_in.password),
        full_name=recruiter_in.full_name,
        email=recruiter_in.email,
        company_name=recruiter_in.company_name,
    )
    db.add(recruiter)
    db.commit()
    db.refresh(recruiter)
    return RecruiterOut(
        id=recruiter.id,
        phone_number=recruiter.phone_number,
        full_name=recruiter.full_name,
        email=recruiter.email,
        company_name=recruiter.company_name,
    )


@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    recruiter = authenticate_recruiter(db, form_data.username, form_data.password)
    if not recruiter:
        raise HTTPException(status_code=401, detail="Incorrect phone number or password")
    access_token = create_access_token(data={"sub": str(recruiter.id)})
    recruiter.last_login = datetime.utcnow()
    db.commit()
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=RecruiterOut)
async def read_current_recruiter(current_recruiter: Recruiter = Depends(get_current_recruiter)):
    return RecruiterOut(
        id=current_recruiter.id,
        phone_number=current_recruiter.phone_number,
        full_name=current_recruiter.full_name,
        email=current_recruiter.email,
        company_name=current_recruiter.company_name,
    )
