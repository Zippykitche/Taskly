import anthropic
import os
import json
from typing import Optional

CLAUDE_API_KEY = os.getenv("CLAUDE_API_KEY")
client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)

class ClaudeAI:
    """Claude AI service for Taskly - replacing E.A.R.L AI"""
    
    # 1. ANALYZE JOB COMPLEXITY FOR PRICING
    @staticmethod
    def analyze_job_complexity(
        title: str,
        description: str,
        category: str,
        urgency: str
    ) -> dict:
        """
        Analyze job and return complexity score (1.0-2.5)
        Higher score = more complex = higher price multiplier
        """
        prompt = f"""You are a job pricing AI for a marketplace. Analyze this job and return ONLY valid JSON (no markdown):

Job Title: {title}
Description: {description}
Category: {category}
Urgency Level: {urgency}

Return ONLY this JSON format (no other text):
{{
    "complexity_score": <float between 1.0 and 2.5>,
    "difficulty_level": "<easy|medium|hard|very_hard>",
    "reasoning": "<brief explanation in 1 sentence>"
}}"""

        try:
            message = client.messages.create(
                model="claude-opus-4-7",
                max_tokens=200,
                messages=[{"role": "user", "content": prompt}]
            )
            
            response_text = message.content[0].text.strip()
            result = json.loads(response_text)
            return result
        except Exception as e:
            print(f"⚠️ Claude complexity analysis failed: {e}")
            # Fallback to default if Claude fails
            return {
                "complexity_score": 1.0,
                "difficulty_level": "medium",
                "reasoning": "Default - Claude unavailable"
            }
    
    # 2. RECOMMEND JOBS FOR TASKERS
    @staticmethod
    def recommend_jobs(
        tasker_categories: list,
        tasker_rating: float,
        available_jobs: list,
        limit: int = 5
    ) -> list:
        """
        Recommend jobs for a tasker based on skills match
        Returns list of (job_id, match_score, reason)
        """
        jobs_str = "\n".join([
            f"- Job {j['job_id']}: {j['title']} ({j['category']}) - Price: {j['price']} KES - Urgency: {j['urgency']}"
            for j in available_jobs[:20]  # Limit to 20 jobs for prompt
        ])
        
        prompt = f"""You are a job matching AI. Match these jobs with a tasker's profile.

Tasker Skills: {', '.join(tasker_categories)}
Tasker Rating: {tasker_rating}/5.0 stars

Available Jobs:
{jobs_str}

Return ONLY valid JSON (no markdown):
[
    {{
        "job_id": <int>,
        "match_score": <float 0.0-1.0>,
        "reason": "<why this is a good match>"
    }}
]

Return top {limit} matches only."""

        try:
            message = client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=500,
                messages=[{"role": "user", "content": prompt}]
            )
            
            response_text = message.content[0].text.strip()
            results = json.loads(response_text)
            return results[:limit]
        except Exception as e:
            print(f"⚠️ Claude recommendations failed: {e}")
            return []
    
    # 3. ENHANCE JOB DESCRIPTION
    @staticmethod
    def enhance_job_description(title: str, description: str) -> dict:
        """
        Improve job description for clarity and appeal
        """
        prompt = f"""Improve this job posting to be clearer and more attractive. Return ONLY valid JSON (no markdown):

Title: {title}
Description: {description}

{{
    "enhanced_description": "<improved description, 2-3 sentences>",
    "suggested_keywords": ["keyword1", "keyword2", "keyword3"],
    "clarity_tip": "<one tip for the recruiter>"
}}"""

        try:
            message = client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}]
            )
            
            response_text = message.content[0].text.strip()
            result = json.loads(response_text)
            return result
        except Exception as e:
            print(f"⚠️ Claude enhancement failed: {e}")
            return {
                "enhanced_description": description,
                "suggested_keywords": [],
                "clarity_tip": "Could not enhance"
            }
    
    # 4. CUSTOMER SUPPORT
    @staticmethod
    def support_chat(user_message: str, conversation_history: Optional[list] = None) -> str:
        """
        Handle customer support requests
        """
        messages = conversation_history or []
        messages.append({"role": "user", "content": user_message})
        
        try:
            message = client.messages.create(
                model="claude-haiku-4-5",  # Fast and cheap
                max_tokens=300,
                system="""You are a friendly Taskly customer support assistant. 
Help users with:
- Job posting and browsing questions
- Payment and withdrawal issues
- Rating and dispute resolution
- Technical problems
Be concise, friendly, and helpful. If you can't help, direct them to email support@taskly.com""",
                messages=messages
            )
            
            return message.content[0].text
        except Exception as e:
            print(f"⚠️ Claude support failed: {e}")
            return "I'm having trouble right now. Please contact support@taskly.com"