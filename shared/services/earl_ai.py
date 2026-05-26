import os
import httpx
from dotenv import load_dotenv

load_dotenv()

EARL_BASE_URL = os.getenv("EARL_BASE_URL", "http://localhost:8001")
EARL_API_KEY = os.getenv("EARL_API_KEY", "")


class EARLAIClient:
    def __init__(self):
        self.base_url = EARL_BASE_URL
        self.api_key = EARL_API_KEY
        self.headers = {"Content-Type": "application/json"}
        if self.api_key:
            self.headers["Authorization"] = f"Bearer {self.api_key}"

    async def chat(self, message: str, context: dict) -> dict:
        payload = {
            "message": message,
            "user_id": f"taskly_{context.get('user_type', 'anonymous')}_{context.get('user_id', '0')}",
            "project_id": "taskly_platform",
            "metadata": context,
        }
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(f"{self.base_url}/chat", json=payload, headers=self.headers)
            response.raise_for_status()
            return response.json()

    async def analyze_job_complexity(self, description: str, category: str, urgency: str, location: str) -> float:
        prompt = (
            f"Analyze this job description for Taskly and return a complexity score between 1.0 and 2.0. "
            f"Category: {category}. Urgency: {urgency}. Location: {location}. Description: {description}"
        )
        result = await self.chat(prompt, {"user_type": "system", "user_id": "earl_analysis"})
        score = result.get("complexity_score") or result.get("score") or result.get("response")
        try:
            return float(score)
        except (TypeError, ValueError):
            return 1.0
