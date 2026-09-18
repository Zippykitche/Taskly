from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def get_reviews():
    return {"message": "Reviews route working"}