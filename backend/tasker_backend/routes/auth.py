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
from shared.models.user import Tasker

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

SECRET_KEY = os.getenv("SECRET_KEY", "tasker-secret-key")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

router = APIRouter()


class TaskerCreate(BaseModel):
    phone_number: str
    password: str
    full_name: str
    id_number: str
    email: Optional[EmailStr] = None


class TaskerOut(BaseModel):
    id: int
    phone_number: str
    full_name: str
    email: Optional[EmailStr] = None
    profile_image_url: Optional[str] = None


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


def get_tasker_by_phone(db: Session, phone: str):
    return db.query(Tasker).filter(Tasker.phone_number == phone).first()


def get_tasker(db: Session, tasker_id: int):
    return db.query(Tasker).filter(Tasker.id == tasker_id).first()


def authenticate_tasker(db: Session, phone: str, password: str):
    tasker = get_tasker_by_phone(db, phone)
    if not tasker or not verify_password(password, tasker.hashed_password):
        return None
    return tasker


async def get_current_tasker(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        tasker_id: int = int(payload.get("sub"))
        if tasker_id is None:
            raise credentials_exception
    except (JWTError, ValueError):
        raise credentials_exception
    tasker = get_tasker(db, tasker_id)
    if tasker is None:
        raise credentials_exception
    return tasker


@router.post("/register", response_model=TaskerOut)
def register(tasker_in: TaskerCreate, db: Session = Depends(get_db)):
    if get_tasker_by_phone(db, tasker_in.phone_number):
        raise HTTPException(status_code=400, detail="Phone number already registered")
    if tasker_in.email and db.query(Tasker).filter(Tasker.email == tasker_in.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    tasker = Tasker(
        phone_number=tasker_in.phone_number,
        hashed_password=get_password_hash(tasker_in.password),
        full_name=tasker_in.full_name,
        email=tasker_in.email,
        id_number=tasker_in.id_number,
    )
    db.add(tasker)
    db.commit()
    db.refresh(tasker)
    return TaskerOut(
        id=tasker.id,
        phone_number=tasker.phone_number,
        full_name=tasker.full_name,
        email=tasker.email,
        profile_image_url=tasker.profile_image_url,
    )


@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    tasker = authenticate_tasker(db, form_data.username, form_data.password)
    if not tasker:
        raise HTTPException(status_code=401, detail="Incorrect phone number or password")
    access_token = create_access_token(data={"sub": str(tasker.id)})
    tasker.last_login = datetime.utcnow()
    db.commit()
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=TaskerOut)
async def read_current_tasker(current_tasker: Tasker = Depends(get_current_tasker)):
    return TaskerOut(
        id=current_tasker.id,
        phone_number=current_tasker.phone_number,
        full_name=current_tasker.full_name,
        email=current_tasker.email,
        profile_image_url=current_tasker.profile_image_url,
    )
