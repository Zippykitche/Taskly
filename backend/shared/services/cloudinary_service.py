import os
from dotenv import load_dotenv
from fastapi import UploadFile
import cloudinary
import cloudinary.uploader

load_dotenv()

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
)


async def upload_profile_image(file: UploadFile, user_type: str, user_id: int) -> str:
    result = cloudinary.uploader.upload(
        file.file,
        folder=f"taskly/{user_type}s/profiles",
        public_id=f"{user_type}_{user_id}",
        overwrite=True,
        transformation=[
            {"width": 400, "height": 400, "crop": "fill"},
            {"quality": "auto"},
        ],
    )
    return result["secure_url"]


async def upload_id_image(file: UploadFile, tasker_id: int) -> str:
    result = cloudinary.uploader.upload(
        file.file,
        folder="taskly/id_verification",
        public_id=f"tasker_{tasker_id}_id",
        overwrite=True,
    )
    return result["secure_url"]


async def upload_job_image(file: UploadFile, job_id: int) -> str:
    result = cloudinary.uploader.upload(
        file.file,
        folder=f"taskly/jobs/{job_id}",
        transformation=[
            {"width": 1200, "crop": "limit"},
            {"quality": "auto"},
        ],
    )
    return result["secure_url"]
