import redis
import time
from functools import wraps
from fastapi import HTTPException, Request
from typing import Optional, Callable
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

load_dotenv()

class RateLimiter:
    """
    Advanced rate limiting with Redis
    Protects against:
    - Brute force attacks
    - API abuse
    - DDoS attacks
    """
    
    def __init__(self, redis_url: str = None):
        """Initialize Redis connection for rate limiting"""
        try:
            if redis_url is None:
                redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
            
            # For local development without Redis, use in-memory fallback
            self.use_redis = False
            self.in_memory_limits = {}
            
            try:
                self.redis_client = redis.from_url(redis_url)
                self.redis_client.ping()
                self.use_redis = True
                print("✅ Redis connected for rate limiting")
            except:
                print("⚠️  Redis not available, using in-memory rate limiting")
                self.redis_client = None
        
        except Exception as e:
            print(f"Rate limiter init error: {str(e)}")
            self.redis_client = None
    
    def is_rate_limited(
        self,
        key: str,
        max_requests: int = 100,
        window_seconds: int = 60
    ) -> bool:
        """
        Check if a key exceeds rate limit
        Returns: True if limited, False if allowed
        """
        try:
            if self.use_redis and self.redis_client:
                # Redis-based rate limiting
                current = self.redis_client.incr(key)
                
                if current == 1:
                    # Set expiry on first request
                    self.redis_client.expire(key, window_seconds)
                
                return current > max_requests
            else:
                # In-memory fallback
                now = time.time()
                
                if key not in self.in_memory_limits:
                    self.in_memory_limits[key] = []
                
                # Remove old requests outside window
                self.in_memory_limits[key] = [
                    req_time for req_time in self.in_memory_limits[key]
                    if now - req_time < window_seconds
                ]
                
                # Check limit
                if len(self.in_memory_limits[key]) >= max_requests:
                    return True
                
                # Add current request
                self.in_memory_limits[key].append(now)
                return False
        
        except Exception as e:
            print(f"Rate limit check error: {str(e)}")
            return False
    
    def get_remaining(self, key: str, max_requests: int = 100) -> int:
        """Get remaining requests for a key"""
        try:
            if self.use_redis and self.redis_client:
                current = self.redis_client.get(key)
                current = int(current) if current else 0
                return max(0, max_requests - current)
            else:
                now = time.time()
                if key in self.in_memory_limits:
                    count = len(self.in_memory_limits[key])
                    return max(0, max_requests - count)
                return max_requests
        except:
            return max_requests

class RateLimitConfig:
    """Rate limiting configuration for different endpoints"""
    
    # Per user, per minute
    AUTH_LIMIT = (5, 60)  # 5 requests per 60 seconds
    LOGIN_LIMIT = (5, 60)  # 5 login attempts per minute
    REGISTER_LIMIT = (3, 300)  # 3 registrations per 5 minutes
    
    # Per user, per hour
    JOB_CREATE_LIMIT = (20, 3600)  # 20 jobs per hour
    JOB_APPLY_LIMIT = (50, 3600)  # 50 applications per hour
    
    # Per IP address
    API_LIMIT = (1000, 3600)  # 1000 requests per hour
    
    # Per user, per day
    WITHDRAWAL_LIMIT = (10, 86400)  # 10 withdrawals per day
    DISPUTE_LIMIT = (5, 86400)  # 5 disputes per day
    
    # AI endpoints (expensive)
    AI_PRICE_LIMIT = (100, 3600)  # 100 pricing requests per hour
    IMAGE_VERIFY_LIMIT = (50, 3600)  # 50 image verifications per hour

# Global rate limiter instance
rate_limiter = RateLimiter()

async def rate_limit_middleware(request: Request, call_next):
    """Middleware to apply rate limiting to all requests"""
    try:
        # Get client IP
        client_ip = request.client.host if request.client else "unknown"
        
        # Get rate limit key
        path = request.url.path
        
        # Different limits for different endpoints
        if "/auth/login" in path:
            max_req, window = RateLimitConfig.LOGIN_LIMIT
            key = f"login:{client_ip}"
        elif "/auth/register" in path:
            max_req, window = RateLimitConfig.REGISTER_LIMIT
            key = f"register:{client_ip}"
        else:
            max_req, window = RateLimitConfig.API_LIMIT
            key = f"api:{client_ip}"
        
        # Check rate limit
        if rate_limiter.is_rate_limited(key, max_req, window):
            raise HTTPException(
                status_code=429,
                detail="Too many requests. Please try again later."
            )
        
        response = await call_next(request)
        return response
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Rate limit middleware error: {str(e)}")
        # Don't block requests if rate limiter fails
        return await call_next(request)

def endpoint_rate_limit(max_requests: int = 100, window_seconds: int = 60):
    """Decorator for per-endpoint rate limiting"""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Extract user_id from current_user if available
            current_user = next((arg for arg in args if hasattr(arg, 'id')), None)
            current_user = current_user or kwargs.get('current_user')
            
            if current_user and hasattr(current_user, 'id'):
                key = f"endpoint:{func.__name__}:user:{current_user.id}"
            else:
                # Fallback to request if available
                request = next((arg for arg in args if isinstance(arg, Request)), None)
                if request and request.client:
                    key = f"endpoint:{func.__name__}:ip:{request.client.host}"
                else:
                    key = f"endpoint:{func.__name__}:unknown"
            
            if rate_limiter.is_rate_limited(key, max_requests, window_seconds):
                raise HTTPException(
                    status_code=429,
                    detail=f"Rate limit exceeded. Max {max_requests} requests per {window_seconds} seconds"
                )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator