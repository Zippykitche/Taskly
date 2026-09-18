from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def get_tasks():
    return {"message": "Tasks route working"}