import os
import httpx
from fastapi import HTTPException

class SupabaseService:
    def __init__(self):
        self.supabase_url = os.getenv("SUPABASE_URL", "").rstrip("/")
        self.supabase_anon_key = os.getenv("SUPABASE_ANON_KEY", "")

    def is_configured(self) -> bool:
        return bool(self.supabase_url and self.supabase_anon_key)

    async def signup_user(self, email: str, password: str) -> dict:
        """
        Signs up a user in Supabase Auth, which triggers the email activation flow.
        """
        if not self.is_configured():
            # Graceful local fallback warning
            return {"id": "mock-supabase-uuid", "email": email}

        url = f"{self.supabase_url}/auth/v1/signup"
        headers = {
            "apikey": self.supabase_anon_key,
            "Content-Type": "application/json"
        }
        json_data = {
            "email": email,
            "password": password
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, json=json_data)
                if response.status_code != 200:
                    error_detail = response.json().get("error_description") or response.json().get("msg") or "Registration failed"
                    raise HTTPException(status_code=response.status_code, detail=error_detail)
                return response.json()
            except httpx.HTTPError as e:
                raise HTTPException(status_code=500, detail=f"Supabase connection error: {str(e)}")

    async def authenticate_user(self, email: str, password: str) -> dict:
        """
        Authenticates a user in Supabase Auth.
        Returns the token payload if successful, otherwise raises an exception (e.g. if email is unconfirmed).
        """
        if not self.is_configured():
            # Graceful local fallback for development
            return {"access_token": "mock-token", "user": {"email": email}}

        url = f"{self.supabase_url}/auth/v1/token?grant_type=password"
        headers = {
            "apikey": self.supabase_anon_key,
            "Content-Type": "application/json"
        }
        json_data = {
            "email": email,
            "password": password
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, headers=headers, json=json_data)
                if response.status_code != 200:
                    error_json = response.json()
                    error_desc = error_json.get("error_description") or ""
                    
                    if "email not confirmed" in error_desc.lower() or error_json.get("error") == "unauthorized_client":
                        raise HTTPException(
                            status_code=400,
                            detail="Please activate your account by clicking the confirmation link sent to your email."
                        )
                    
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=error_desc or "Invalid email or password"
                    )
                return response.json()
            except httpx.HTTPError as e:
                raise HTTPException(status_code=500, detail=f"Supabase connection error: {str(e)}")

supabase_service = SupabaseService()
