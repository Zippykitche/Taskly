import jwt
import os
from datetime import datetime, timedelta
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

class JWTSecurity:
    """
    JWT token management with security hardening
    """
    
    SECRET_KEY = os.getenv("JWT_SECRET", "change-this-in-production")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 15  # Short expiry for security
    REFRESH_TOKEN_EXPIRE_DAYS = 7
    
    # Token blacklist for logout
    token_blacklist = set()
    
    @staticmethod
    def create_access_token(
        data: dict,
        expires_delta: Optional[timedelta] = None,
        audience: str = "taskly-app"
    ) -> str:
        """
        Create JWT access token with security headers
        - Short expiry
        - Audience validation
        - Issued at claim
        """
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(
                minutes=JWTSecurity.ACCESS_TOKEN_EXPIRE_MINUTES
            )
        
        # Add security claims
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),
            "aud": audience,
            "type": "access"
        })
        
        encoded_jwt = jwt.encode(
            to_encode,
            JWTSecurity.SECRET_KEY,
            algorithm=JWTSecurity.ALGORITHM
        )
        
        return encoded_jwt
    
    @staticmethod
    def create_refresh_token(data: dict) -> str:
        """Create refresh token for obtaining new access tokens"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(
            days=JWTSecurity.REFRESH_TOKEN_EXPIRE_DAYS
        )
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),
            "type": "refresh"
        })
        
        encoded_jwt = jwt.encode(
            to_encode,
            JWTSecurity.SECRET_KEY,
            algorithm=JWTSecurity.ALGORITHM
        )
        
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str, audience: str = "taskly-app") -> dict:
        """
        Verify JWT token with security checks
        - Signature verification
        - Expiry check
        - Audience validation
        - Blacklist check
        """
        try:
            # Check if token is blacklisted (logged out)
            if token in JWTSecurity.token_blacklist:
                raise jwt.InvalidTokenError("Token has been revoked")
            
            payload = jwt.decode(
                token,
                JWTSecurity.SECRET_KEY,
                algorithms=[JWTSecurity.ALGORITHM],
                audience=audience
            )
            
            return payload
        
        except jwt.ExpiredSignatureError:
            raise jwt.ExpiredSignatureError("Token has expired")
        except jwt.InvalidAudienceError:
            raise jwt.InvalidAudienceError("Invalid token audience")
        except jwt.InvalidTokenError as e:
            raise jwt.InvalidTokenError(f"Invalid token: {str(e)}")
    
    @staticmethod
    def blacklist_token(token: str):
        """Add token to blacklist on logout"""
        JWTSecurity.token_blacklist.add(token)
    
    @staticmethod
    def is_token_expired(token: str) -> bool:
        """Check if token is expired"""
        try:
            jwt.decode(
                token,
                JWTSecurity.SECRET_KEY,
                algorithms=[JWTSecurity.ALGORITHM],
                options={"verify_exp": True}
            )
            return False
        except jwt.ExpiredSignatureError:
            return True
        except:
            return True