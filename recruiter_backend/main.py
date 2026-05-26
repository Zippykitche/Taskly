import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from shared.database import init_db
from recruiter_backend.routes.auth import router as auth_router
from recruiter_backend.routes.jobs import router as jobs_router
from recruiter_backend.routes.payments import router as payments_router
from recruiter_backend.routes.hire import router as hire_router

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

app = FastAPI(title="Taskly Recruiter Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(jobs_router, prefix="/jobs", tags=["jobs"])
app.include_router(payments_router, prefix="/payments", tags=["payments"])
app.include_router(hire_router, prefix="/hire", tags=["hire"])


@app.on_event("startup")
def startup_event():
    init_db()
