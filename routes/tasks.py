from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

import auth
import models
import schemas
from database import SessionLocal

router = APIRouter()

# CREATE a new task
@router.post("/", response_model=schemas.TaskResponse)
def create_task(
    task: schemas.TaskCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """
    Create a new task (client_id is automatically retrieved from JWT token)
    """
    db_task = models.Task(
        **task.dict(),
        client_id=current_user.id,
        status=models.TaskStatus.posted
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

# GET all tasks
@router.get("/", response_model=List[schemas.TaskResponse])
def get_tasks(db: Session = Depends(auth.get_db)):
    """Get all tasks in the system"""
    tasks = db.query(models.Task).all()
    return tasks

# Search and filtering - MUST come before /{task_id}
@router.get("/search", response_model=List[schemas.TaskResponse])
def search_tasks(
    location: Optional[str] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(auth.get_db)
):
    """
    Search and filter tasks
    - location: Filter by location (partial match)
    - min_price: Minimum price
    - max_price: Maximum price
    - status: Task status (posted, assigned, in_progress, completed)
    """
    query = db.query(models.Task)
    
    # Filter by location (case-insensitive partial match)
    if location:
        query = query.filter(models.Task.location.ilike(f"%{location}%"))
    
    # Filter by price range
    if min_price is not None:
        query = query.filter(models.Task.price >= min_price)
    if max_price is not None:
        query = query.filter(models.Task.price <= max_price)
    
    # Filter by status
    if status:
        try:
            task_status = models.TaskStatus[status]
            query = query.filter(models.Task.status == task_status)
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status. Must be one of: {[s.value for s in models.TaskStatus]}"
            )
    
    return query.all()

# GET single task by ID
@router.get("/{task_id}", response_model=schemas.TaskResponse)
def get_task(task_id: int, db: Session = Depends(auth.get_db)):
    """Get a specific task by ID"""
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

# CLAIM a task (tasker assigns themselves)
@router.post("/{task_id}/claim")
def claim_task(
    task_id: int, 
    current_user: models.User = Depends(auth.get_current_user), 
    db: Session = Depends(auth.get_db)
):
    """
    Tasker claims an available task (tasker_id is retrieved from JWT token)
    """
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status != models.TaskStatus.posted:
        raise HTTPException(status_code=400, detail="Task is not available")
    
    task.tasker_id = current_user.id
    task.status = models.TaskStatus.assigned
    db.commit()
    db.refresh(task)
    return {"message": "Task claimed successfully", "task": task}

# COMPLETE a task
@router.post("/{task_id}/complete")
def complete_task(
    task_id: int, 
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """
    Mark a task as completed. 
    Only the assigned tasker can complete the task.
    """
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.tasker_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the assigned tasker can complete this task")

    task.status = models.TaskStatus.completed
    db.commit()
    db.refresh(task)
    return {"message": "Task marked as completed", "task": task}