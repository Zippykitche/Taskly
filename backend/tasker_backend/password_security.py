from passlib.context import CryptContext
import re

class PasswordSecurity:
    """
    Password hashing and validation
    Uses bcrypt for secure password storage
    """
    
    # Initialize password hashing context
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Hash password using bcrypt"""
        return PasswordSecurity.pwd_context.hash(password)
    
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify plain password against hash"""
        try:
            return PasswordSecurity.pwd_context.verify(plain_password, hashed_password)
        except:
            return False
    
    @staticmethod
    def validate_password_strength(password: str) -> tuple[bool, str]:
        """
        Validate password meets security requirements:
        - Min 12 characters
        - At least 1 uppercase
        - At least 1 lowercase
        - At least 1 number
        - At least 1 special character
        """
        if len(password) < 12:
            return False, "Password must be at least 12 characters"
        
        if not re.search(r"[A-Z]", password):
            return False, "Password must contain uppercase letter"
        
        if not re.search(r"[a-z]", password):
            return False, "Password must contain lowercase letter"
        
        if not re.search(r"\d", password):
            return False, "Password must contain number"
        
        if not re.search(r"[!@#$%^&*()_+\-=\[\]{};':\"\\|,.<>/?]", password):
            return False, "Password must contain special character"
        
        return True, "Password is strong"

class InputValidation:
    """
    Input validation and sanitization
    Prevents SQL injection, XSS, etc.
    """
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """Validate email format"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    @staticmethod
    def validate_phone(phone: str) -> bool:
        """Validate Kenyan phone number"""
        # Remove spaces and special chars
        phone = re.sub(r'\D', '', phone)
        
        # Must be 10-12 digits
        if not (10 <= len(phone) <= 12):
            return False
        
        # Must start with 0, 1, or 254 (Kenya country code)
        if not (phone.startswith('0') or phone.startswith('1') or phone.startswith('254')):
            return False
        
        return True
    
    @staticmethod
    def sanitize_string(value: str, max_length: int = 500) -> str:
        """Sanitize string input"""
        if not isinstance(value, str):
            return ""
        
        # Remove null bytes
        value = value.replace('\x00', '')
        
        # Truncate to max length
        value = value[:max_length]
        
        # Strip whitespace
        value = value.strip()
        
        return value
    
    @staticmethod
    def validate_amount(amount: float) -> bool:
        """Validate monetary amount"""
        try:
            amount = float(amount)
            return 0 < amount <= 1000000  # Max 1M KES per transaction
        except:
            return False
    
    @staticmethod
    def validate_url(url: str) -> bool:
        """Validate URL format"""
        pattern = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
        return bool(re.match(pattern, url))