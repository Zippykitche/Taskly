import json
import os

try:
    import anthropic
except ImportError:
    anthropic = None


def _get_client():
    api_key = os.getenv("CLAUDE_API_KEY")
    if not anthropic or not api_key:
        return None
    return anthropic.Anthropic(api_key=api_key)


class ImageVerification:
    @staticmethod
    def compare_before_after(
        before_image_url: str,
        after_image_url: str,
        job_category: str,
    ) -> dict:
        """
        Compare before/after images using Claude Vision.
        Returns match percentage, quality assessment, and release recommendation.
        """
        non_visual_jobs = ["Nanny", "Tutoring", "House Help", "Coaching"]

        if job_category in non_visual_jobs:
            return {
                "requires_images": False,
                "match_percentage": 100,
                "quality_assessment": "Not applicable for this job type",
                "issues_found": [],
                "recommendation": "RELEASE",
                "confidence": 100,
            }

        client = _get_client()
        if not client:
            return {
                "requires_images": True,
                "match_percentage": 0,
                "quality_assessment": "Image verification is not configured",
                "issues_found": ["Missing Claude SDK or CLAUDE_API_KEY"],
                "recommendation": "MANUAL_REVIEW",
                "confidence": 0,
            }

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
                            {"type": "text", "text": prompt},
                            {
                                "type": "image",
                                "source": {"type": "url", "url": before_image_url},
                            },
                            {
                                "type": "image",
                                "source": {"type": "url", "url": after_image_url},
                            },
                        ],
                    }
                ],
            )

            return json.loads(response.content[0].text)
        except Exception as exc:
            return {
                "requires_images": True,
                "match_percentage": 0,
                "quality_assessment": "Failed to assess",
                "issues_found": [str(exc)],
                "recommendation": "MANUAL_REVIEW",
                "confidence": 0,
            }

    @staticmethod
    def verify_profile_picture_quality(image_url: str) -> dict:
        """Verify profile picture quality."""
        client = _get_client()
        if not client:
            return {
                "approved": False,
                "feedback": "Image verification is not configured",
            }

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
                                """,
                            },
                            {
                                "type": "image",
                                "source": {"type": "url", "url": image_url},
                            },
                        ],
                    }
                ],
            )
            return json.loads(response.content[0].text)
        except Exception as exc:
            return {"approved": False, "feedback": f"Could not verify: {exc}"}
