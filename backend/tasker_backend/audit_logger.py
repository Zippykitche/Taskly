from datetime import datetime
from sqlalchemy.orm import Session
from shared.models.db_models import User
import json
import os

class AuditLogger:
    """
    Audit logging for security events
    Tracks: logins, failed attempts, payment changes, data access
    """
    
    AUDIT_LOG_FILE = "audit_logs/security_audit.log"
    
    @staticmethod
    def ensure_log_dir():
        """Ensure audit log directory exists"""
        os.makedirs("audit_logs", exist_ok=True)
    
    @staticmethod
    def log_event(
        event_type: str,
        user_id: int = None,
        user_email: str = None,
        ip_address: str = None,
        action: str = None,
        status: str = "SUCCESS",
        details: dict = None
    ):
        """
        Log security event
        Event types: LOGIN, FAILED_LOGIN, LOGOUT, REGISTER, PAYMENT, WITHDRAWAL, DATA_ACCESS, DISPUTE
        """
        AuditLogger.ensure_log_dir()
        
        try:
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": event_type,
                "user_id": user_id,
                "user_email": user_email,
                "ip_address": ip_address,
                "action": action,
                "status": status,
                "details": details or {}
            }
            
            # Write to file
            with open(AuditLogger.AUDIT_LOG_FILE, "a") as f:
                f.write(json.dumps(log_entry) + "\n")
            
            # Alert on suspicious activity
            AuditLogger.check_suspicious_activity(event_type, user_id, ip_address)
        
        except Exception as e:
            print(f"Audit logging error: {str(e)}")
    
    @staticmethod
    def check_suspicious_activity(event_type: str, user_id: int = None, ip_address: str = None):
        """Detect and alert on suspicious patterns"""
        try:
            # Count failed logins in last hour
            if event_type == "FAILED_LOGIN":
                # TODO: Alert if > 5 failed logins from same IP in 1 hour
                pass
            
            # Check for unusual payment amounts
            if event_type == "PAYMENT":
                # TODO: Alert if payment > 100K KES
                pass
            
            # Multiple withdrawals in short time
            if event_type == "WITHDRAWAL":
                # TODO: Alert if > 3 withdrawals in 1 hour
                pass
        
        except Exception as e:
            print(f"Suspicious activity check error: {str(e)}")
    
    @staticmethod
    def get_audit_log(user_id: int = None, limit: int = 100) -> list:
        """Retrieve audit logs for a user"""
        try:
            AuditLogger.ensure_log_dir()
            logs = []
            
            if not os.path.exists(AuditLogger.AUDIT_LOG_FILE):
                return []
            
            with open(AuditLogger.AUDIT_LOG_FILE, "r") as f:
                for line in f.readlines()[-limit:]:
                    try:
                        entry = json.loads(line)
                        if user_id is None or entry.get("user_id") == user_id:
                            logs.append(entry)
                    except:
                        pass
            
            return logs
        
        except Exception as e:
            print(f"Error reading audit log: {str(e)}")
            return []