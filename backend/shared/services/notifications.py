from __future__ import annotations
import asyncio
import os
from datetime import datetime
import httpx
from dotenv import load_dotenv
from shared.models.notification import DeviceToken, NotificationLog

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


async def _send_push_async(
    user_id: int,
    user_type: str,
    title: str,
    body: str,
    db,
    data: dict | None = None,
) -> None:
    tokens = db.query(DeviceToken).filter(
        DeviceToken.user_type == user_type,
        DeviceToken.user_id == user_id,
        DeviceToken.active == True,
    ).all()

    if not tokens:
        return

    device_tokens = [token.device_token for token in tokens]
    client = FCMClient()
    response = await client.send_bulk(device_tokens, title, body, data)

    log = NotificationLog(
        user_type=user_type,
        user_id=user_id,
        title=title,
        body=body,
        data=data or {},
        sent=True,
        response=response,
        sent_at=datetime.utcnow(),
    )
    db.add(log)
    db.commit()


def send_push(
    user_id: int,
    user_type: str,
    title: str,
    body: str,
    db,
    data: dict | None = None,
) -> None:
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        asyncio.run(_send_push_async(user_id, user_type, title, body, db, data))
        return

    loop.create_task(_send_push_async(user_id, user_type, title, body, db, data))
