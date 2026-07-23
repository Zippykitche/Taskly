from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from services.taskly_ai_client import taskly_ai
import auth
import models
import schemas

router = APIRouter()

@router.get("/recommended")
async def get_recommended_jobs(
    current_user: models.User = Depends(auth.get_current_worker),
    db: Session = Depends(auth.get_db)
):
    # Get available tasks (filtering by location if provided)
    query = db.query(models.Task).filter(models.Task.status == models.TaskStatus.posted)
    
    if current_user.location:
        query = query.filter(models.Task.location.ilike(f"%{current_user.location}%"))
    
    tasks = query.limit(50).all()
    
    if not tasks:
        return {"jobs": [], "message": "No jobs available"}
    
    # Convert SQLAlchemy models to dicts for the AI service
    tasks_data = [schemas.TaskResponse.from_orm(task).dict() for task in tasks]
    
    # Get AI rankings based on worker profile
    ranked = await taskly_ai.rank_jobs(
        tasker_profile={
            "id": current_user.id,
            "skills": current_user.skills,
            "location": current_user.location
        },
        jobs=tasks_data
    )
    
    return {"jobs": ranked}
