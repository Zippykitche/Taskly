from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import relationship

from shared.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, unique=True, index=True)
    password = Column(String)
    full_name = Column(String)
    email = Column(String, unique=True, index=True)
    user_type = Column(String)
    id_number = Column(String, nullable=True)
    categories = Column(JSON, nullable=True)
    location_city = Column(String)
    location_area = Column(String)
    profile_picture_url = Column(String, nullable=True)
    cloudinary_id = Column(String, nullable=True)
    rating = Column(Float, default=5.0)
    total_jobs = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    jobs = relationship("Job", back_populates="recruiter")
    applications = relationship("Application", back_populates="tasker")
    wallet = relationship("Wallet", back_populates="user", uselist=False)
    ratings_given = relationship(
        "Rating",
        foreign_keys="Rating.rater_id",
        back_populates="rater",
    )
    ratings_received = relationship(
        "Rating",
        foreign_keys="Rating.ratee_id",
        back_populates="ratee",
    )
    disputes_opened = relationship(
        "Dispute",
        foreign_keys="Dispute.opened_by_id",
        back_populates="opened_by",
    )
    receipts = relationship("Receipt", back_populates="user")


class Job(Base):
    __tablename__ = "jobs"
    __table_args__ = {"extend_existing": True}
    __mapper_args__ = {"exclude_properties": ["images"]}

    id = Column(Integer, primary_key=True)
    title = Column(String)
    description = Column(Text)
    category = Column(String)
    location_city = Column(String)
    location_area = Column(String)
    location_address = Column(String)
    urgency = Column(String)
    price = Column(Float)
    recruiter_id = Column(Integer, ForeignKey("users.id"))
    recruiter_phone = Column(String)
    status = Column(String, default="open")
    created_at = Column(DateTime, default=datetime.utcnow)

    recruiter = relationship("User", back_populates="jobs")
    applications = relationship("Application", back_populates="job")
    images = relationship("WorkImage", back_populates="job")
    receipts = relationship("Receipt", back_populates="job")


class Application(Base):
    __tablename__ = "applications"

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, ForeignKey("jobs.id"))
    tasker_id = Column(Integer, ForeignKey("users.id"))
    tasker_phone = Column(String)
    cover_letter = Column(String)
    status = Column(String, default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)

    job = relationship("Job", back_populates="applications")
    tasker = relationship("User", back_populates="applications")


class WorkImage(Base):
    __tablename__ = "work_images"

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, ForeignKey("jobs.id"))
    uploaded_by = Column(String)
    image_url = Column(String)
    image_type = Column(String)
    cloudinary_id = Column(String)
    uploaded_at = Column(DateTime, default=datetime.utcnow)

    job = relationship("Job", back_populates="images")


class Wallet(Base):
    __tablename__ = "wallets"
    __table_args__ = {"extend_existing": True}

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    balance = Column(Float, default=0.0)
    available_withdrawal = Column(Float, default=0.0)
    total_earned = Column(Float, default=0.0)
    updated_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="wallet")


class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = {"extend_existing": True}

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float)
    type = Column(String)
    job_id = Column(Integer, nullable=True)
    status = Column(String, default="pending")
    mpesa_reference = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Rating(Base):
    __tablename__ = "ratings"
    __table_args__ = {"extend_existing": True}

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, ForeignKey("jobs.id"), nullable=False)
    rater_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    ratee_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    score = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    job = relationship("Job")
    rater = relationship("User", foreign_keys=[rater_id], back_populates="ratings_given")
    ratee = relationship("User", foreign_keys=[ratee_id], back_populates="ratings_received")


class Dispute(Base):
    __tablename__ = "disputes"
    __table_args__ = {"extend_existing": True}

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, ForeignKey("jobs.id"), nullable=False)
    opened_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reason = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    status = Column(String, default="open")
    resolution = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)

    job = relationship("Job")
    opened_by = relationship("User", foreign_keys=[opened_by_id], back_populates="disputes_opened")


class Receipt(Base):
    __tablename__ = "receipts"

    id = Column(Integer, primary_key=True, index=True)
    receipt_code = Column(String, unique=True, index=True, nullable=False)
    job_id = Column(Integer, ForeignKey("jobs.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    commission_amount = Column(Float, default=0.0)
    net_amount = Column(Float, nullable=False)
    tax_amount = Column(Float, default=0.0)
    status = Column(String, default="pending")
    pdf_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    paid_at = Column(DateTime, nullable=True)

    job = relationship("Job", back_populates="receipts")
    user = relationship("User", back_populates="receipts")


class DailyReport(Base):
    __tablename__ = "daily_reports"

    id = Column(Integer, primary_key=True, index=True)
    report_date = Column(String, unique=True, index=True, nullable=False)
    total_jobs = Column(Integer, default=0)
    gross_earnings = Column(Float, default=0.0)
    total_commission = Column(Float, default=0.0)
    total_tax = Column(Float, default=0.0)
    net_earnings = Column(Float, default=0.0)
    pdf_url = Column(String, nullable=True)
    sent_to_email = Column(Boolean, default=False)
    sent_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
