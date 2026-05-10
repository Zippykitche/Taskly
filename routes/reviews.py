from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

import models
import schemas
import auth
from database import SessionLocal

router = APIRouter()

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_review(
    review: schemas.ReviewCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """
    Create a review for a completed task
    Requires authentication
    """
    # Verify task exists
    task = db.query(models.Task).filter(models.Task.id == review.task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    # Verify task is completed
    if task.status != models.TaskStatus.completed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only review completed tasks"
        )
    
    # Verify user was part of the task (either client or tasker)
    if current_user.id not in [task.client_id, task.tasker_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only review tasks you were involved in"
        )
    
    # Check if user already reviewed this task
    existing_review = db.query(models.Review).filter(
        models.Review.task_id == review.task_id,
        models.Review.reviewer_id == current_user.id
    ).first()
    
    if existing_review:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already reviewed this task"
        )
    
    # Validate rating
    if review.rating < 1 or review.rating > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    # Create review
    db_review = models.Review(
        rating=review.rating,
        comment=review.comment,
        task_id=review.task_id,
        reviewer_id=current_user.id
    )
    
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    
    return {
        "message": "Review created successfully",
        "review_id": db_review.id,
        "rating": db_review.rating,
        "task_id": db_review.task_id
    }

@router.get("/", response_model=List[schemas.ReviewResponse])
def get_all_reviews(db: Session = Depends(auth.get_db)):
    """Get all reviews"""
    reviews = db.query(models.Review).all()
    return reviews

@router.get("/task/{task_id}", response_model=List[schemas.ReviewResponse])
def get_task_reviews(task_id: int, db: Session = Depends(auth.get_db)):
    """Get all reviews for a specific task"""
    return db.query(models.Review).filter(models.Review.task_id == task_id).all()