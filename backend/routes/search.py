from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
import models, schemas, auth

router = APIRouter()

@router.get("/", response_model=List[schemas.UserResponse])
def global_search(
    skill: Optional[str] = None,
    db: Session = Depends(auth.get_db)
):
    """Quick discovery search for workers by skill"""
    query = db.query(models.User).filter(models.User.role == models.UserRole.worker)
    if skill:
        query = query.filter(models.User.skills.ilike(f"%{skill}%"))
    return query.all()