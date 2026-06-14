from enum import Enum
from datetime import datetime

class ImageType(str, Enum):
    BEFORE = "before"
    AFTER = "after"
    PROFILE = "profile"

class WorkImage:
    def __init__(self, image_id: int, job_id: int, uploaded_by: str, 
                 image_url: str, image_type: ImageType, cloudinary_id: str):
        self.image_id = image_id
        self.job_id = job_id
        self.uploaded_by = uploaded_by  # tasker or recruiter
        self.image_url = image_url
        self.image_type = image_type
        self.cloudinary_id = cloudinary_id
        self.uploaded_at = datetime.utcnow().isoformat()

class ProfilePicture:
    def __init__(self, user_phone: str, image_url: str, cloudinary_id: str):
        self.user_phone = user_phone
        self.image_url = image_url
        self.cloudinary_id = cloudinary_id
        self.uploaded_at = datetime.utcnow().isoformat()