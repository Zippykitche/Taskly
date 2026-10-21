from fastapi import APIRouter, Depends
from services.taskly_ai_client import taskly_ai
import auth
import models

router = APIRouter()

@router.post("/chat")
async def chat_with_support(
    message: str,
    current_user: models.User = Depends(auth.get_current_user)
):
    user_context = {
        "user_type": current_user.role.value,
        "user_id": str(current_user.id),
        "name": current_user.name,
        # Placeholder values for fields not yet in DB schema
        "active_jobs": 0,
        "verification_status": "verified"
    }
    
    response = await taskly_ai.support_chat(message, user_context)
    
    return response