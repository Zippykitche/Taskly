import httpx
import os
from typing import Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()


class EARLAIClient:
    def __init__(self):
        self.base_url = os.getenv("EARL_AI_URL", "http://localhost:8001")
        self.api_key = os.getenv("TASKLY_API_KEY")

    async def chat(
        self,
        message: str,
        user_id: str,
        user_type: str,
        context: Optional[Dict[Any, Any]] = None,
    ) -> str:
        payload = {
            "message": message,
            "user_id": f"taskly_{user_type}_{user_id}",
            "project_id": "taskly_platform",
        }

        headers = {
            "X-Taskly-Key": self.api_key,
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.base_url}/chat",
                json=payload,
                headers=headers,
            )

            if response.status_code == 200:
                return response.json()["response"]
            else:
                raise Exception(f"E.A.R.L AI error: {response.text}")

    async def analyze_job_complexity(
        self,
        category: str,
        description: str,
    ) -> float:
        prompt = f"""Analyze this job for pricing:

Category: {category}
Description: {description}

Return ONLY JSON:
{{
  "complexity_score": 1.0-2.0,
  "estimated_hours": float,
  "skill_level": "basic|intermediate|expert",
  "reasoning": "brief explanation"
}}"""

        response = await self.chat(
            message=prompt,
            user_id="pricing_system",
            user_type="system",
        )

        import json
        clean = response.strip()
        if clean.startswith("```json"):
            clean = clean.split("```json")[1].split("```")[0].strip()
        elif clean.startswith("```"):
            clean = clean.split("```")[1].split("```")[0].strip()

        parsed = json.loads(clean)
        return float(parsed.get("complexity_score", 1.0))

    async def rank_jobs_for_tasker(
        self,
        tasker_profile: Dict[str, Any],
        jobs: list,
    ) -> list:
        jobs_text = "\n\n".join([
            f"Job {i+1}:\n- ID: {job['id']}\n- Title: {job['title']}\n"
            f"- Category: {job['category']}\n- Price: KES {job['price']}\n"
            f"- Location: {job['location']}"
            for i, job in enumerate(jobs)
        ])

        prompt = f"""Rank these jobs for this tasker:

Tasker:
- Skills: {', '.join(tasker_profile.get('categories', []))}
- Rating: {tasker_profile.get('rating', 0)}/5
- Jobs completed: {tasker_profile.get('jobs_completed', 0)}
- Location: {tasker_profile.get('location', 'Unknown')}

Jobs:
{jobs_text}

Return ONLY JSON array:
[{{"job_id": 1, "match_score": 95, "why": "reason"}}]"""

        response = await self.chat(
            message=prompt,
            user_id=str(tasker_profile.get("id")),
            user_type="tasker",
        )

        import json
        clean = response.strip()
        if clean.startswith("```json"):
            clean = clean.split("```json")[1].split("```")[0].strip()
        elif clean.startswith("```"):
            clean = clean.split("```")[1].split("```")[0].strip()

        return json.loads(clean)


earl_client = EARLAIClient()
