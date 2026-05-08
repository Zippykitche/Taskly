from fastapi import FastAPI
from routes import users, tasks, reviews
from database import engine, Base
import models

app = FastAPI()

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
app.include_router(reviews.router, prefix="/reviews", tags=["reviews"])

@app.get("/")
def root():
    return {"message": "Taskly API running"}