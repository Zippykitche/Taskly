from fastapi import FastAPI

from routes import users, tasks, reviews

app = FastAPI()

app.include_router(users.router, prefix="/users")
app.include_router(tasks.router, prefix="/tasks")
app.include_router(reviews.router, prefix="/reviews")

@app.get("/")
def root():
    return {"message": "Taskly API running"}