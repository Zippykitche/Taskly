import os
from dotenv import load_dotenv

load_dotenv()

class SecretsManager:
    """
    Centralized secrets management
    Never hardcode secrets - always use environment variables
    """
    
    @staticmethod
    def get_secret(key: str, default: str = None) -> str:
        """Get secret from environment variables"""
        value = os.getenv(key)
        
        if value is None:
            if default is None:
                raise ValueError(f"Secret '{key}' not found in environment")
            return default
        
        return value
    
    @staticmethod
    def validate_required_secrets():
        """Validate all required secrets are configured"""
        required_secrets = [
            "JWT_SECRET",
            "DATABASE_URL",
            "CLAUDE_API_KEY",
            "SENDGRID_API_KEY",
            "MPESA_CONSUMER_KEY",
            "MPESA_CONSUMER_SECRET",
        ]
        
        missing = []
        for secret in required_secrets:
            if not os.getenv(secret):
                missing.append(secret)
        
        if missing:
            raise ValueError(f"Missing required secrets: {', '.join(missing)}")
        
        return True
    
    # Cached secret values (loaded once on startup)
    _secrets_cache = {}
    
    @staticmethod
    def load_all_secrets():
        """Load all secrets into cache on startup"""
        SecretsManager._secrets_cache = {
            "JWT_SECRET": SecretsManager.get_secret("JWT_SECRET"),
            "DATABASE_URL": SecretsManager.get_secret("DATABASE_URL"),
            "CLAUDE_API_KEY": SecretsManager.get_secret("CLAUDE_API_KEY"),
            "SENDGRID_API_KEY": SecretsManager.get_secret("SENDGRID_API_KEY"),
            "MPESA_CONSUMER_KEY": SecretsManager.get_secret("MPESA_CONSUMER_KEY"),
            "MPESA_CONSUMER_SECRET": SecretsManager.get_secret("MPESA_CONSUMER_SECRET"),
        }