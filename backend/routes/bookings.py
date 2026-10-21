from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

import auth
import models
import schemas

router = APIRouter()

@router.post("/", response_model=schemas.BookingResponse, status_code=status.HTTP_201_CREATED)
def create_booking(
    booking: schemas.BookingCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """
    Recruiter creates a new booking request for a specific worker.
    Initial status is 'pending'.
    """
    if current_user.role != models.UserRole.recruiter:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only recruiters can create bookings"
        )
    
    # Verify worker exists and is actually a worker
    worker = db.query(models.User).filter(models.User.id == booking.worker_id).first()
    if not worker or worker.role != models.UserRole.worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found or is not a worker"
        )

    new_booking = models.Booking(
        recruiter_id=current_user.id,
        worker_id=booking.worker_id,
        title=booking.title,
        description=booking.description,
        location=booking.location,
        date=booking.date,
        time=booking.time,
        status=models.BookingStatus.pending,
        created_at=datetime.utcnow()
    )
    
    # Create Notification for Worker
    new_notification = models.Notification(
        user_id=booking.worker_id,
        message=f"New booking request from {current_user.name}: {booking.title}"
    )
    db.add(new_notification)
    
    db.add(new_booking)
    db.commit()
    db.refresh(new_booking)
    return new_booking

@router.get("/", response_model=List[schemas.BookingResponse])
def get_my_bookings(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """
    Get all bookings for the current authenticated user (recruiter or worker).
    """
    if current_user.role == models.UserRole.recruiter:
        bookings = db.query(models.Booking).filter(models.Booking.recruiter_id == current_user.id).all()
    else: # Worker
        bookings = db.query(models.Booking).filter(models.Booking.worker_id == current_user.id).all()
    return bookings

@router.get("/{booking_id}", response_model=schemas.BookingResponse)
def get_booking_details(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """Get details of a specific booking, accessible by involved recruiter or worker."""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if current_user.id not in [booking.recruiter_id, booking.worker_id]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to view this booking"
        )
    return booking

@router.post("/{booking_id}/accept", response_model=schemas.BookingResponse)
def accept_booking(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """Worker accepts a pending booking request."""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if current_user.id != booking.worker_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not the assigned worker for this booking")
    
    if booking.status != models.BookingStatus.pending:
        raise HTTPException(status_code=400, detail=f"Booking cannot be accepted in '{booking.status}' status")
    
    booking.status = models.BookingStatus.accepted
    
    # Create Notification for Recruiter
    notification = models.Notification(
        user_id=booking.recruiter_id,
        message=f"Your booking for '{booking.title}' was accepted by {current_user.name}!"
    )
    db.add(notification)
    
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/{booking_id}/decline", response_model=schemas.BookingResponse)
def decline_booking(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(auth.get_db)
):
    """Worker declines a pending booking request."""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if current_user.id != booking.worker_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not the assigned worker for this booking")
    
    if booking.status != models.BookingStatus.pending:
        raise HTTPException(status_code=400, detail=f"Booking cannot be declined in '{booking.status}' status")
    
    booking.status = models.BookingStatus.declined

    # Create Notification for Recruiter
    notification = models.Notification(
        user_id=booking.recruiter_id,
        message=f"Your booking for '{booking.title}' was declined."
    )
    db.add(notification)

    db.commit()
    db.refresh(booking)
    return booking

# Additional status updates (in_progress, completed, cancelled) can be added similarly
# For example, a worker can mark a booking as in_progress or completed.
# A recruiter or worker can cancel a booking depending on its status.
# These are good candidates for future iterations to define precise permissions.