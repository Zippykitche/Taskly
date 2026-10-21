import os
import httpx
from fastapi import HTTPException

class FirebaseService:
    def __init__(self):
        self.api_key = os.getenv("FIREBASE_WEB_API_KEY") or os.getenv("FIREBASE_API_KEY", "")

    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def signup_user(self, email: str, password: str) -> dict:
        """
        Signs up a user in Firebase Auth and triggers the email verification flow.
        """
        if not self.is_configured():
            # Graceful local fallback for development
            return {"id": "mock-firebase-uuid", "email": email}

        signup_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={self.api_key}"
        headers = {"Content-Type": "application/json"}
        json_data = {
            "email": email,
            "password": password,
            "returnSecureToken": True
        }

        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                response = await client.post(signup_url, headers=headers, json=json_data)
                if response.status_code != 200:
                    error_detail = "Registration failed"
                    try:
                        res_json = response.json()
                        error_detail = res_json.get("error", {}).get("message", "Registration failed")
                    except Exception:
                        pass
                    if response.status_code in (400, 422):
                        raise HTTPException(status_code=400, detail=error_detail)
                    return {"id": "local-fallback-uuid", "email": email}

                signup_res = response.json()
                id_token = signup_res.get("idToken")

                # Send verification email if idToken is returned
                if id_token:
                    verify_url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={self.api_key}"
                    verify_data = {
                        "requestType": "VERIFY_EMAIL",
                        "idToken": id_token
                    }
                    await client.post(verify_url, headers=headers, json=verify_data)

                return signup_res
            except HTTPException:
                raise
            except Exception:
                return {"id": "local-fallback-uuid", "email": email}

    async def authenticate_user(self, email: str, password: str) -> dict:
        """
        Authenticates a user in Firebase Auth.
        Verifies password and email confirmation status.
        """
        if not self.is_configured():
            # Graceful local fallback for development
            return {"idToken": "mock-token", "email": email}

        login_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={self.api_key}"
        headers = {"Content-Type": "application/json"}
        json_data = {
            "email": email,
            "password": password,
            "returnSecureToken": True
        }

        async with httpx.AsyncClient(timeout=5.0) as client:
            try:
                response = await client.post(login_url, headers=headers, json=json_data)
                if response.status_code != 200:
                    error_json = response.json()
                    error_msg = error_json.get("error", {}).get("message", "")

                    if "INVALID_PASSWORD" in error_msg or "EMAIL_NOT_FOUND" in error_msg:
                        raise HTTPException(status_code=401, detail="Incorrect email or password.")

                    raise HTTPException(
                        status_code=response.status_code,
                        detail=error_msg or "Authentication failed"
                    )

                auth_res = response.json()
                id_token = auth_res.get("idToken")

                # Check email verification status
                lookup_url = f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={self.api_key}"
                lookup_data = {"idToken": id_token}
                lookup_res = await client.post(lookup_url, headers=headers, json=lookup_data)

                if lookup_res.status_code == 200:
                    users = lookup_res.json().get("users", [])
                    if users and not users[0].get("emailVerified", False):
                        raise HTTPException(
                            status_code=400,
                            detail="Please activate your account by clicking the confirmation link sent to your email."
                        )

                return auth_res
            except HTTPException:
                raise
            except httpx.HTTPError as e:
                raise HTTPException(status_code=500, detail=f"Firebase connection error: {str(e)}")

firebase_service = FirebaseService()
