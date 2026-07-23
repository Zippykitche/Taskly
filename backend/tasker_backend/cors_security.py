from fastapi.middleware.cors import CORSMiddleware
import os

def configure_cors(app):
    """
    Configure CORS with security best practices
    """
    
    # Only allow specific origins (not *)
    allowed_origins = [
        "http://localhost:3000",  # Local frontend dev
        "http://localhost:8000",  # Local testing
        "https://taskly.app",  # Production
        "https://www.taskly.app",
    ]
    
    # Don't use * in production
    if os.getenv("ENVIRONMENT") == "production":
        app.add_middleware(
            CORSMiddleware,
            allow_origins=allowed_origins,
            allow_credentials=True,
            allow_methods=["GET", "POST", "PUT", "DELETE"],
            allow_headers=["*"],
            max_age=600,  # Cache preflight for 10 minutes
            expose_headers=["X-Total-Count"]
        )
    else:
        # More permissive in development
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )