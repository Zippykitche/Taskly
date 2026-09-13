from sqlalchemy import Column, Integer, String, DateTime, Enum
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import enum

Base = declarative_base()

class TransactionStatus(enum.Enum):
    PENDING = "pending"
    ESCROWED = "escrowed"
    RELEASED = "released"
    REFUNDED = "refunded"
    FAILED = "failed"

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer, nullable=False, index=True)
    recruiter_id = Column(Integer, nullable=False, index=True)
    tasker_id = Column(Integer, nullable=False, index=True)
    
    # Amounts (in KES cents)
    total_amount = Column(Integer, nullable=False)
    tasker_amount = Column(Integer, nullable=False)
    platform_commission = Column(Integer, nullable=False)
    
    # Status
    status = Column(Enum(TransactionStatus), default=TransactionStatus.PENDING)
    
    # M-Pesa details
    mpesa_receipt_number = Column(String(50), nullable=True)
    mpesa_transaction_id = Column(String(50), nullable=True)
    mpesa_phone_number = Column(String(15), nullable=True)
    
    # Timestamps
    paid_at = Column(DateTime, nullable=True)
    escrowed_at = Column(DateTime, nullable=True)
    released_at = Column(DateTime, nullable=True)
    refunded_at = Column(DateTime, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            "id": self.id,
            "job_id": self.job_id,
            "amount": self.total_amount / 100,
            "status": self.status.value,
            "created_at": self.created_at.isoformat()
        }

class Withdrawal(Base):
    __tablename__ = "withdrawals"
    
    id = Column(Integer, primary_key=True, index=True)
    tasker_id = Column(Integer, nullable=False, index=True)
    
    amount = Column(Integer, nullable=False)
    status = Column(String(20), default="pending")
    
    # M-Pesa B2C details
    mpesa_conversation_id = Column(String(50), nullable=True)
    mpesa_result_code = Column(String(10), nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)