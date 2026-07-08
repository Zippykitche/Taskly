from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from shared.database import get_db
from shared.models.notification import DeviceToken, NotificationLog
from shared.services.notifications import FCMClient
from shared.models.user import Tasker
from tasker_backend.routes.auth import get_current_tasker

router = APIRouter()

fcm_client = FCMClient()


class DeviceTokenPayload(BaseModel):
    device_token: str
    platform: str
    app_version: str | None = None


class NotificationPayload(BaseModel):
    title: str
    body: str
    data: dict | None = None


@router.post("/devices/register")
async def register_device(payload: DeviceTokenPayload, current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    token = db.query(DeviceToken).filter(DeviceToken.device_token == payload.device_token).first()
    if token:
        token.user_type = "tasker"
        token.user_id = current_tasker.id
        token.platform = payload.platform
        token.app_version = payload.app_version
        token.active = True
        token.updated_at = datetime.utcnow()
    else:
        token = DeviceToken(
            user_type="tasker",
            user_id=current_tasker.id,
            device_token=payload.device_token,
            platform=payload.platform,
            app_version=payload.app_version,
            active=True,
        )
        db.add(token)
    db.commit()
    return {"status": "registered", "device_token": payload.device_token}


@router.post("/devices/unregister")
async def unregister_device(payload: DeviceTokenPayload, current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    token = db.query(DeviceToken).filter(DeviceToken.device_token == payload.device_token, DeviceToken.user_id == current_tasker.id).first()
    if not token:
        raise HTTPException(status_code=404, detail="Device token not found")
    token.active = False
    db.commit()
    return {"status": "unregistered", "device_token": payload.device_token}


@router.post("/send")
async def send_notification(payload: NotificationPayload, current_tasker: Tasker = Depends(get_current_tasker), db: Session = Depends(get_db)):
    tokens = db.query(DeviceToken).filter(DeviceToken.user_type == "tasker", DeviceToken.user_id == current_tasker.id, DeviceToken.active == True).all()
    if not tokens:
        raise HTTPException(status_code=404, detail="No registered device tokens")
    device_tokens = [t.device_token for t in tokens]
    response = await fcm_client.send_bulk(device_tokens, payload.title, payload.body, payload.data)
    log = NotificationLog(
        user_type="tasker",
        user_id=current_tasker.id,
        title=payload.title,
        body=payload.body,
        data=payload.data or {},
        sent=True,
        response=response,
        sent_at=datetime.utcnow(),
    )
    db.add(log)
    db.commit()
    return {"sent": True, "tokens": len(device_tokens), "response": response}
