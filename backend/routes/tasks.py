from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

import models
import schemas
from database import SessionLocal

router = APIRouter()

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# CREATE a new task
@router.post("/", response_model=schemas.TaskResponse)
def create_task(task: schemas.TaskCreate, client_id: int, db: Session = Depends(get_db)):
    """
    Create a new task (for testing, we're passing client_id as a query param)
    Later: get client_id from JWT token
    """
    db_task = models.Task(
        title=task.title,
        description=task.description,
        price=task.price,
        location=task.location,
        client_id=client_id,
        status=models.TaskStatus.posted
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

# GET all tasks
@router.get("/", response_model=List[schemas.TaskResponse])
def get_tasks(db: Session = Depends(get_db)):
    """Get all tasks in the system"""
    tasks = db.query(models.Task).all()
    return tasks

# Search and filtering - MUST come before /{task_id}
@router.get("/search")
def search_tasks(
    location: Optional[str] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
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
    
    tasks = query.all()
    
    return [
        {
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "price": task.price,
            "location": task.location,
            "status": task.status.value,
            "client_id": task.client_id,
            "tasker_id": task.tasker_id
        }
        for task in tasks
    ]

# GET single task by ID
@router.get("/{task_id}", response_model=schemas.TaskResponse)
def get_task(task_id: int, db: Session = Depends(get_db)):
    """Get a specific task by ID"""
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

# CLAIM a task (tasker assigns themselves)
@router.post("/{task_id}/claim")
def claim_task(task_id: int, tasker_id: int, db: Session = Depends(get_db)):
    """
    Tasker claims an available task
    Later: get tasker_id from JWT token
    """
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status != models.TaskStatus.posted:
        raise HTTPException(status_code=400, detail="Task is not available")
    
    task.tasker_id = tasker_id
    task.status = models.TaskStatus.assigned
    db.commit()
    db.refresh(task)
    return {"message": "Task claimed successfully", "task": task}

# COMPLETE a task
@router.post("/{task_id}/complete")
def complete_task(task_id: int, db: Session = Depends(get_db)):
    """Mark a task as completed"""
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task.status = models.TaskStatus.completed
    db.commit()
    db.refresh(task)
    return {"message": "Task marked as completed", "task": task}