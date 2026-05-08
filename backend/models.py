from sqlalchemy import Column, Integer, String, ForeignKey, Enum
from sqlalchemy.orm import relationship
from database import Base
import enum

class UserRole(str, enum.Enum):
    client = "client"
    tasker = "tasker"

class TaskStatus(str, enum.Enum):
    posted = "posted"
    assigned = "assigned"
    in_progress = "in_progress"
    completed = "completed"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    email = Column(String, unique=True)
    password = Column(String)
    role = Column(Enum(UserRole))
    phone = Column(String)

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True)
    title = Column(String)
    description = Column(String)
    price = Column(Integer)
    location = Column(String)

    status = Column(Enum(TaskStatus), default=TaskStatus.posted)

    client_id = Column(Integer, ForeignKey("users.id"))
    tasker_id = Column(Integer, ForeignKey("users.id"), nullable=True)

class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True)
    rating = Column(Integer)
    comment = Column(String)

    task_id = Column(Integer, ForeignKey("tasks.id"))
    reviewer_id = Column(Integer, ForeignKey("users.id"))