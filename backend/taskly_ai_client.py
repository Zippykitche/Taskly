import httpx
from fastapi import HTTPException
import os

class TasklyAIClient:
    def __init__(self):
        self.base_url = os.getenv("EARL_AI_URL", "http://localhost:8001/taskly")
        self.api_key = os.getenv("TASKLY_API_KEY")
        
        if not self.api_key:
            raise ValueError("TASKLY_API_KEY environment variable must be set")
    
    async def support_chat(self, message: str, user_context: dict) -> dict:
        """Get AI support response from E.A.R.L"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(
                    f"{self.base_url}/chat/support",
                    json={
                        "message": message,
                        "user_context": user_context
                    },
                    headers={"X-Taskly-Key": self.api_key}
                )
                response.raise_for_status()
                return response.json()
            except httpx.HTTPError as e:
                raise HTTPException(503, f"TasklyAI unavailable: {str(e)}")
    
    async def rank_jobs(self, tasker_profile: dict, jobs: list) -> list:
        """Get AI job rankings from E.A.R.L"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                response = await client.post(
                    f"{self.base_url}/matching/rank-jobs",
                    json={
                        "tasker_profile": tasker_profile,
                        "available_jobs": jobs
                    },
                    headers={"X-Taskly-Key": self.api_key}
                )
                response.raise_for_status()
                return response.json()["ranked_jobs"]
            except httpx.HTTPError as e:
                raise HTTPException(503, f"TasklyAI unavailable: {str(e)}")

# Singleton
taskly_ai = TasklyAIClient()