import os
from datetime import datetime
import httpx
from dotenv import load_dotenv

load_dotenv()

FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")
FCM_URL = "https://fcm.googleapis.com/fcm/send"


class FCMClient:
    def __init__(self, server_key: str | None = None):
        self.server_key = server_key or FCM_SERVER_KEY
        self.url = FCM_URL

    async def send_push(self, token: str, title: str, body: str, data: dict | None = None) -> dict:
        if not self.server_key:
            raise ValueError("FCM server key is not configured")

        payload = {
            "to": token,
            "priority": "high",
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
            },
            "data": data or {},
        }
        headers = {
            "Authorization": f"key={self.server_key}",
            "Content-Type": "application/json",
        }
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(self.url, json=payload, headers=headers)
            response.raise_for_status()
            return response.json()

    async def send_bulk(self, tokens: list[str], title: str, body: str, data: dict | None = None) -> dict:
        if not self.server_key:
            raise ValueError("FCM server key is not configured")

        payload = {
            "registration_ids": tokens,
            "priority": "high",
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
            },
            "data": data or {},
        }
        headers = {
            "Authorization": f"key={self.server_key}",
            "Content-Type": "application/json",
        }
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(self.url, json=payload, headers=headers)
            response.raise_for_status()
            return response.json()
