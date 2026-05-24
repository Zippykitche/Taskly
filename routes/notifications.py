from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
import auth, models, schemas

router = APIRouter()

@router.get("/", response_model=List[schemas.NotificationResponse])
def get_my_notifications(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """Get all notifications for the logged in user"""
    return db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id
    ).order_by(models.Notification.created_at.desc()).all()

@router.post("/{notification_id}/read")
def mark_as_read(
    notification_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """Mark a specific notification as read"""
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == current_user.id
    ).first()
    if notification:
        notification.is_read = True
        db.commit()
    return {"message": "Marked as read"}