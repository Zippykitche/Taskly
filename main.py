from fastapi import FastAPI
from routes import users, tasks, reviews, bookings, notifications, search, payments, support, jobs
from database import engine, Base
import models

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
app.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
app.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
app.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
app.include_router(search.router, prefix="/search", tags=["search"])
app.include_router(payments.router, prefix="/payments", tags=["payments"])
app.include_router(support.router, prefix="/support", tags=["support"])
app.include_router(jobs.router, prefix="/jobs", tags=["jobs"])

@app.get("/")
def root():
    return {"message": "Taskly API running"}