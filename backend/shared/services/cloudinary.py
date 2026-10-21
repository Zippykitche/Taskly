import os
from dotenv import load_dotenv
import cloudinary
import cloudinary.uploader

load_dotenv()

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", ""),
    api_key=os.getenv("CLOUDINARY_API_KEY", ""),
    api_secret=os.getenv("CLOUDINARY_API_SECRET", ""),
    secure=True,
)


def upload_image(file_obj, folder: str, public_id: str):
    result = cloudinary.uploader.upload(
        file_obj,
        folder=folder,
        public_id=public_id,
        overwrite=True,
        resource_type="image",
    )
    return result.get("secure_url")
