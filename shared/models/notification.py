from sqlalchemy import Column, Integer, String, DateTime, JSON, Boolean
from datetime import datetime
from . import Base


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_type = Column(String(20), nullable=False)
    user_id = Column(Integer, nullable=False, index=True)
    device_token = Column(String(255), nullable=False, unique=True, index=True)
    platform = Column(String(20), nullable=False)
    app_version = Column(String(50), nullable=True)
    active = Column(Boolean, default=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_type = Column(String(20), nullable=False)
    user_id = Column(Integer, nullable=False, index=True)
    title = Column(String(200), nullable=False)
    body = Column(String(500), nullable=False)
    data = Column(JSON, default=dict)
    sent = Column(Boolean, default=False)
    response = Column(JSON, default=dict)

    created_at = Column(DateTime, default=datetime.utcnow)
    sent_at = Column(DateTime, nullable=True)
