import os
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from dotenv import load_dotenv
from shared.database import get_db
from shared.models.user import Tasker
from shared.services.cloudinary import upload_image
from tasker_backend.routes.auth import get_current_tasker

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

router = APIRouter()


class ProfileUpdate(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    bio: str | None = None
    location_city: str | None = None
    location_area: str | None = None
    categories: list[str] | None = None


@router.get("/me")
def get_profile(current_tasker: Tasker = Depends(get_current_tasker)):
    return current_tasker.to_dict()


@router.put("/me")
def update_profile(payload: ProfileUpdate, current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    if payload.full_name is not None:
        current_tasker.full_name = payload.full_name
    if payload.email is not None:
        current_tasker.email = str(payload.email)
    if payload.bio is not None:
        current_tasker.bio = payload.bio
    if payload.location_city is not None:
        current_tasker.location_city = payload.location_city
    if payload.location_area is not None:
        current_tasker.location_area = payload.location_area
    if payload.categories is not None:
        current_tasker.categories = payload.categories
    db.commit()
    db.refresh(current_tasker)
    return current_tasker.to_dict()


@router.post("/upload-image")
def upload_profile_image(file: UploadFile = File(...), current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    if file.content_type.split("/")[0] != "image":
        raise HTTPException(status_code=400, detail="Only image uploads are allowed")
    url = upload_image(file.file, folder="taskly/profiles", public_id=f"tasker_{current_tasker.id}")
    current_tasker.profile_image_url = url
    db.commit()
    db.refresh(current_tasker)
    return {"image_url": url}
