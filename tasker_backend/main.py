import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from shared.database import init_db
from tasker_backend.routes.auth import router as auth_router
from tasker_backend.routes.jobs import router as jobs_router
from tasker_backend.routes.earnings import router as earnings_router
from tasker_backend.routes.profile import router as profile_router

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

app = FastAPI(title="Taskly Tasker Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(jobs_router, prefix="/jobs", tags=["jobs"])
app.include_router(earnings_router, prefix="/earnings", tags=["earnings"])
app.include_router(profile_router, prefix="/profile", tags=["profile"])


@app.on_event("startup")
def startup_event():
    init_db()
