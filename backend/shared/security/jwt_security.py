import os
from datetime import datetime, timedelta, timezone
from typing import Optional

import jwt
from dotenv import load_dotenv

load_dotenv()


class JWTSecurity:
    """JWT helpers with short-lived access tokens and blacklist support."""

    SECRET_KEY = os.getenv("JWT_SECRET", "taskly-dev-secret-change-me")
    ALGORITHM = "HS256"
    ISSUER = "taskly"
    ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))
    token_blacklist = set()

    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None, audience: str = "taskly-app") -> str:
        to_encode = data.copy()
        now = datetime.now(timezone.utc)
        if expires_delta:
            expire = now + expires_delta
        else:
            expire = now + timedelta(minutes=JWTSecurity.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({
            "exp": int(expire.timestamp()),
            "iat": int(now.timestamp()),
            "nbf": int(now.timestamp()),
            "iss": JWTSecurity.ISSUER,
            "aud": audience,
            "type": "access",
        })
        return jwt.encode(to_encode, JWTSecurity.SECRET_KEY, algorithm=JWTSecurity.ALGORITHM)

    @staticmethod
    def create_refresh_token(data: dict, audience: str = "taskly-app") -> str:
        now = datetime.now(timezone.utc)
        expire = now + timedelta(days=JWTSecurity.REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode = data.copy()
        to_encode.update({
            "exp": int(expire.timestamp()),
            "iat": int(now.timestamp()),
            "nbf": int(now.timestamp()),
            "iss": JWTSecurity.ISSUER,
            "aud": audience,
            "type": "refresh",
        })
        return jwt.encode(to_encode, JWTSecurity.SECRET_KEY, algorithm=JWTSecurity.ALGORITHM)

    @staticmethod
    def verify_token(token: str, audience: str = "taskly-app") -> dict:
        if not token:
            raise jwt.InvalidTokenError("Token is required")
        if token in JWTSecurity.token_blacklist:
            raise jwt.InvalidTokenError("Token has been revoked")
        return jwt.decode(token, JWTSecurity.SECRET_KEY, algorithms=[JWTSecurity.ALGORITHM], audience=audience, issuer=JWTSecurity.ISSUER)

    @staticmethod
    def blacklist_token(token: str) -> None:
        if token:
            JWTSecurity.token_blacklist.add(token)

    @staticmethod
    def is_token_expired(token: str) -> bool:
        try:
            JWTSecurity.verify_token(token)
            return False
        except jwt.ExpiredSignatureError:
            return True
        except Exception:
            return True
