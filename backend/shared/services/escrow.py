from sqlalchemy.orm import Session
from shared.models.transaction import Transaction, TransactionStatus
from shared.models.job import Job, JobStatus
from shared.models.user import Wallet, Tasker
from shared.services.mpesa import mpesa_client
from shared.services.notifications import send_push
from datetime import datetime
import os

PLATFORM_COMMISSION = 0.15  # 15%
MIN_ESCROW_AMOUNT = 100  # cents


class EscrowService:
    
    @staticmethod
    async def initiate_payment(
        db: Session,
        job_id: int,
        recruiter_id: int,
        tasker_id: int,
        total_amount: int,  # In cents
        phone_number: str
    ) -> Transaction:
        """
        Step 1: Recruiter initiates payment via M-Pesa STK Push
        Money goes into escrow
        """
        
        if total_amount < MIN_ESCROW_AMOUNT:
            raise ValueError("Escrow amount is too small")

        # Calculate split
        platform_cut = int(total_amount * PLATFORM_COMMISSION)
        tasker_earnings = total_amount - platform_cut
        
        # Create transaction record
        transaction = Transaction(
            job_id=job_id,
            recruiter_id=recruiter_id,
            tasker_id=tasker_id,
            total_amount=total_amount,
            tasker_amount=tasker_earnings,
            platform_commission=platform_cut,
            status=TransactionStatus.PENDING
        )
        
        db.add(transaction)
        db.commit()
        db.refresh(transaction)
        
        # Initiate M-Pesa STK Push
        callback_url = f"{os.getenv('API_BASE_URL')}/payments/mpesa/callback"
        
        try:
            normalized_phone = ''.join(ch for ch in phone_number if ch.isdigit())
            if not normalized_phone.startswith(("254", "0", "1")):
                raise ValueError("Unsupported phone number for M-Pesa")

            mpesa_response = await mpesa_client.stk_push(
                phone_number=normalized_phone,
                amount=max(1, total_amount // 100),  # Convert cents to KES
                account_reference=f"Job-{job_id}",
                transaction_desc=f"Payment for Taskly Job #{job_id}",
                callback_url=callback_url
            )
            
            # Store M-Pesa transaction ID
            if mpesa_response.get("ResponseCode") == "0":
                transaction.mpesa_transaction_id = mpesa_response.get("CheckoutRequestID")
                db.commit()
            
        except Exception as e:
            transaction.status = TransactionStatus.FAILED
            db.commit()
            raise Exception(f"M-Pesa payment failed: {str(e)}")
        
        return transaction
    
    @staticmethod
    def confirm_payment(
        db: Session,
        transaction_id: int,
        mpesa_receipt: str
    ):
        """
        Step 2: M-Pesa callback confirms payment
        Money now in escrow
        """
        transaction = db.query(Transaction).filter_by(id=transaction_id).first()
        
        if not transaction:
            raise Exception("Transaction not found")
        
        if not mpesa_receipt or len(mpesa_receipt.strip()) < 4:
            raise ValueError("Invalid M-Pesa receipt")

        transaction.status = TransactionStatus.ESCROWED
        transaction.mpesa_receipt_number = mpesa_receipt.strip()
        transaction.paid_at = datetime.utcnow()
        transaction.escrowed_at = datetime.utcnow()
        
        # Update job status
        job = db.query(Job).filter_by(id=transaction.job_id).first()
        job.status = JobStatus.ASSIGNED
        job.assigned_at = datetime.utcnow()
        
        # Add to tasker's pending balance
        wallet = db.query(Wallet).filter_by(tasker_id=transaction.tasker_id).first()
        if not wallet:
            wallet = Wallet(tasker_id=transaction.tasker_id)
            db.add(wallet)
        
        wallet.pending_balance += transaction.tasker_amount
        
        db.commit()
        
        # Notify tasker
        send_push(
            user_id=transaction.tasker_id,
            user_type="tasker",
            title="Payment Received!",
            body=f"KES {transaction.total_amount/100:.2f} is now in escrow for Job #{transaction.job_id}",
            db=db
        )
    
    @staticmethod
    async def release_payment(
        db: Session,
        job_id: int,
        released_by: str  # "recruiter" or "admin"
    ):
        """
        Step 3: Job completed, release money to tasker
        """
        transaction = db.query(Transaction).filter_by(job_id=job_id).first()
        
        if not transaction:
            raise Exception("Transaction not found")
        
        if transaction.status != TransactionStatus.ESCROWED:
            raise Exception(f"Cannot release payment in status: {getattr(transaction.status, 'value', transaction.status)}")
        
        # Update transaction
        transaction.status = TransactionStatus.RELEASED
        transaction.released_at = datetime.utcnow()
        
        # Move money from pending to available
        wallet = db.query(Wallet).filter_by(tasker_id=transaction.tasker_id).first()
        if not wallet:
            wallet = Wallet(tasker_id=transaction.tasker_id)
            db.add(wallet)
        if wallet.pending_balance < transaction.tasker_amount:
            raise ValueError("Insufficient escrow balance to release funds")
        wallet.pending_balance -= transaction.tasker_amount
        wallet.available_balance += transaction.tasker_amount
        wallet.total_earned += transaction.tasker_amount
        
        # Update job
        job = db.query(Job).filter_by(id=job_id).first()
        job.status = JobStatus.COMPLETED
        job.completed_at = datetime.utcnow()
        
        # Update tasker stats
        tasker = db.query(Tasker).filter_by(id=transaction.tasker_id).first()
        tasker.jobs_completed += 1
        tasker.total_earnings += transaction.tasker_amount
        
        db.commit()
        
        # Notify tasker
        send_push(
            user_id=transaction.tasker_id,
            user_type="tasker",
            title="Payment Released! 🎉",
            body=f"KES {transaction.tasker_amount/100:.2f} is now available for withdrawal",
            db=db
        )
    
    @staticmethod
    async def refund_payment(
        db: Session,
        job_id: int,
        reason: str
    ):
        """
        Step 3 (Alternative): Job cancelled/disputed, refund recruiter
        """
        transaction = db.query(Transaction).filter_by(job_id=job_id).first()
        
        if not transaction:
            raise Exception("Transaction not found")
        
        if transaction.status != TransactionStatus.ESCROWED:
            raise Exception(f"Cannot refund payment in status: {getattr(transaction.status, 'value', transaction.status)}")
        
        # Update transaction
        transaction.status = TransactionStatus.REFUNDED
        transaction.refunded_at = datetime.utcnow()
        
        # Remove from tasker's pending balance
        wallet = db.query(Wallet).filter_by(tasker_id=transaction.tasker_id).first()
        if not wallet:
            wallet = Wallet(tasker_id=transaction.tasker_id)
            db.add(wallet)
        if wallet.pending_balance < transaction.tasker_amount:
            raise ValueError("Insufficient escrow balance to refund funds")
        wallet.pending_balance -= transaction.tasker_amount
        
        # Update job
        job = db.query(Job).filter_by(id=job_id).first()
        job.status = JobStatus.CANCELLED
        
        db.commit()
        
        # Notify both parties
        send_push(
            user_id=transaction.recruiter_id,
            user_type="recruiter",
            title="Payment Refunded",
            body=f"Your payment for Job #{job_id} has been refunded. Reason: {reason}",
            db=db
        )
        
        send_push(
            user_id=transaction.tasker_id,
            user_type="tasker",
            title="Job Cancelled",
            body=f"Job #{job_id} was cancelled. Reason: {reason}",
            db=db
        )


escrow = EscrowService()
