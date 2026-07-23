from __future__ import annotations
import os
import time
from functools import wraps
from typing import Callable

import redis
from dotenv import load_dotenv
from fastapi import HTTPException, Request

load_dotenv()


class RateLimiter:
    """Simple in-memory/Redis-backed rate limiter."""

    def __init__(self, redis_url: str | None = None):
        self.redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379")
        self.in_memory_limits = {}
        self.use_redis = False
        self.redis_client = None
        try:
            self.redis_client = redis.from_url(self.redis_url)
            self.redis_client.ping()
            self.use_redis = True
        except Exception:
            self.redis_client = None

    def is_rate_limited(self, key: str, max_requests: int = 5, window_seconds: int = 60) -> bool:
        if self.use_redis and self.redis_client:
            current = self.redis_client.incr(key)
            if current == 1:
                self.redis_client.expire(key, window_seconds)
            return current > max_requests

        now = time.time()
        bucket = self.in_memory_limits.setdefault(key, [])
        bucket[:] = [ts for ts in bucket if now - ts < window_seconds]
        if len(bucket) >= max_requests:
            return True
        bucket.append(now)
        return False


class RateLimitConfig:
    AUTH_LIMIT = (5, 60)
    LOGIN_LIMIT = (5, 60)
    REGISTER_LIMIT = (3, 300)
    API_LIMIT = (100, 60)
    WITHDRAWAL_LIMIT = (5, 86400)


rate_limiter = RateLimiter()


async def rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host if request.client else "unknown"
    path = request.url.path
    if "/auth/login" in path:
        max_req, window = RateLimitConfig.LOGIN_LIMIT
        key = f"login:{client_ip}"
    elif "/auth/register" in path:
        max_req, window = RateLimitConfig.REGISTER_LIMIT
        key = f"register:{client_ip}"
    else:
        max_req, window = RateLimitConfig.API_LIMIT
        key = f"api:{client_ip}"

    if rate_limiter.is_rate_limited(key, max_req, window):
        raise HTTPException(status_code=429, detail="Too many requests. Please try again later.")
    return await call_next(request)


def endpoint_rate_limit(max_requests: int = 100, window_seconds: int = 60):
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            request = next((arg for arg in args if isinstance(arg, Request)), None)
            if request and request.client:
                key = f"endpoint:{func.__name__}:{request.client.host}"
            else:
                key = f"endpoint:{func.__name__}:unknown"
            if rate_limiter.is_rate_limited(key, max_requests, window_seconds):
                raise HTTPException(status_code=429, detail="Rate limit exceeded")
            return await func(*args, **kwargs)
        return wrapper
    return decorator
