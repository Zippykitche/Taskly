import re
from typing import Tuple
from passlib.context import CryptContext


class PasswordSecurity:
    """Secure password hashing and validation."""

    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    @staticmethod
    def hash_password(password: str) -> str:
        if not password:
            raise ValueError("Password cannot be empty")
        return PasswordSecurity.pwd_context.hash(password)

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        if not plain_password or not hashed_password:
            return False
        try:
            return PasswordSecurity.pwd_context.verify(plain_password, hashed_password)
        except Exception:
            return False

    @staticmethod
    def validate_password_strength(password: str) -> Tuple[bool, str]:
        if not isinstance(password, str):
            return False, "Password must be a string"
        if len(password) < 12:
            return False, "Password must be at least 12 characters"
        if not re.search(r"[A-Z]", password):
            return False, "Password must contain an uppercase letter"
        if not re.search(r"[a-z]", password):
            return False, "Password must contain a lowercase letter"
        if not re.search(r"\d", password):
            return False, "Password must contain a number"
        if not re.search(r"[^A-Za-z0-9]", password):
            return False, "Password must contain a special character"
        if password.lower() in {"password", "password123", "qwerty123"}:
            return False, "Password is too common"
        return True, "Password is strong"


class InputValidation:
    """Input validation helpers."""

    @staticmethod
    def validate_email(email: str) -> bool:
        pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        return bool(re.match(pattern, email or ""))

    @staticmethod
    def validate_phone(phone: str) -> bool:
        phone = re.sub(r"\D", "", phone or "")
        if not (10 <= len(phone) <= 12):
            return False
        return phone.startswith(("0", "1", "254"))

    @staticmethod
    def sanitize_string(value: str, max_length: int = 500) -> str:
        if not isinstance(value, str):
            return ""
        value = value.replace("\x00", "").strip()
        return value[:max_length]

    @staticmethod
    def validate_amount(amount: float) -> bool:
        try:
            amount = float(amount)
            return 0 < amount <= 1000000
        except Exception:
            return False

    @staticmethod
    def validate_url(url: str) -> bool:
        pattern = r"^https?://(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&//=]*)$"
        return bool(re.match(pattern, url or ""))
