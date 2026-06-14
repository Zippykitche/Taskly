import anthropic
import base64
import os
import json
from typing import Optional

client = anthropic.Anthropic(api_key=os.getenv("CLAUDE_API_KEY"))

class ImageVerification:
    @staticmethod
    def compare_before_after(before_image_url: str, after_image_url: str, 
                            job_category: str) -> dict:
        """
        Compare before/after images using Claude Vision
        Returns: {match_percentage, quality_assessment, recommendation}
        """
        
        # Skip image comparison for certain job types (babysitting, tutoring, etc.)
        non_visual_jobs = ["Nanny", "Tutoring", "House Help", "Coaching"]
        
        if job_category in non_visual_jobs:
            return {
                "requires_images": False,
                "match_percentage": 100,
                "quality_assessment": "Not applicable for this job type",
                "recommendation": "Can release funds without images"
            }
        
        # For visual jobs, ask Claude to compare
        prompt = f"""
        You are a quality verification AI for a gig marketplace. 
        Two images have been provided: one BEFORE the work started, and one AFTER the work was completed.
        
        Job Category: {job_category}
        
        Please analyze both images and:
        1. Compare the work quality (0-100% match)
        2. Assess if the work was completed satisfactorily
        3. Check for any red flags
        
        Respond in JSON format:
        {{
            "match_percentage": <0-100>,
            "quality_assessment": "<brief assessment>",
            "issues_found": [<list any issues>],
            "recommendation": "RELEASE" or "HOLD",
            "confidence": <0-100>
        }}
        
        Be fair but strict. Only recommend RELEASE if work quality is >= 85%.
        """
        
        try:
            response = client.messages.create(
                model="claude-opus-4-6",
                max_tokens=500,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": prompt
                            },
                            {
                                "type": "image",
                                "source": {
                                    "type": "url",
                                    "url": before_image_url
                                }
                            },
                            {
                                "type": "image",
                                "source": {
                                    "type": "url",
                                    "url": after_image_url
                                }
                            }
                        ]
                    }
                ]
            )
            
            result_text = response.content[0].text
            return json.loads(result_text)
        except Exception as e:
            print(f"⚠️ Image verification failed: {e}")
            return {
                "match_percentage": 0,
                "quality_assessment": "Failed to assess",
                "recommendation": "MANUAL_REVIEW"
            }
    
    @staticmethod
    def verify_profile_picture_quality(image_url: str) -> dict:
        """
        Verify profile picture quality (face visible, good lighting, etc.)
        """
        try:
            response = client.messages.create(
                model="claude-opus-4-6",
                max_tokens=300,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": """Analyze this profile picture and verify:
                                1. Is a face clearly visible?
                                2. Is the image of acceptable quality?
                                3. Are there any issues (poor lighting, blur, etc.)?
                                
                                Respond in JSON:
                                {
                                    "face_visible": true/false,
                                    "quality": "good/acceptable/poor",
                                    "approved": true/false,
                                    "feedback": "<brief feedback>"
                                }
                                """
                            },
                            { "type": "image", "source": { "type": "url", "url": image_url } }
                        ]
                    }
                ]
            )
            return json.loads(response.content[0].text)
        except Exception:
            return {"approved": False, "feedback": "Could not verify"}