import json
import os
from datetime import datetime
from pathlib import Path


class AuditLogger:
    """Append-only audit logger for authentication and payment events."""

    AUDIT_LOG_FILE = Path(os.getenv("AUDIT_LOG_FILE", "audit_logs/security_audit.log"))

    @staticmethod
    def ensure_log_dir() -> None:
        AuditLogger.AUDIT_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def log_event(event_type: str, user_id: int | None = None, user_email: str | None = None, ip_address: str | None = None, action: str | None = None, status: str = "SUCCESS", details: dict | None = None) -> None:
        try:
            AuditLogger.ensure_log_dir()
            entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": event_type,
                "user_id": user_id,
                "user_email": user_email,
                "ip_address": ip_address,
                "action": action,
                "status": status,
                "details": details or {},
            }
            with AuditLogger.AUDIT_LOG_FILE.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(entry) + "\n")
        except Exception:
            pass
