import hashlib
import re
from passlib.context import CryptContext


class PasswordSecurity:
    """Secure password hashing and validation."""

    pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

    @staticmethod
    def _normalize_password(password: str) -> str:
        if not isinstance(password, str):
            password = str(password or "")
        password = password.encode("utf-8", "ignore").decode("utf-8", "ignore")
        if len(password.encode("utf-8")) > 72:
            password = password[:72]
        return password

    @staticmethod
    def _fallback_hash(password: str) -> str:
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), b"taskly", 100000)
        return f"$pbkdf2-sha256$100000$taskly${digest.hex()}"

    @staticmethod
    def hash_password(password: str) -> str:
        if not password:
            raise ValueError("Password cannot be empty")
        normalized = PasswordSecurity._normalize_password(password)
        try:
            return PasswordSecurity.pwd_context.hash(normalized)
        except Exception:
            return PasswordSecurity._fallback_hash(normalized)

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        if not plain_password or not hashed_password:
            return False
        try:
            normalized_plain = PasswordSecurity._normalize_password(plain_password)
            return PasswordSecurity.pwd_context.verify(normalized_plain, hashed_password)
        except Exception:
            if hashed_password.startswith("$pbkdf2-sha256$"):
                parts = hashed_password.split("$")
                if len(parts) >= 5:
                    digest_hex = parts[-1]
                    return hashlib.pbkdf2_hmac("sha256", normalized_plain.encode("utf-8"), b"taskly", 100000).hex() == digest_hex
            return False

    @staticmethod
    def validate_password_strength(password: str) -> tuple[bool, str]:
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
