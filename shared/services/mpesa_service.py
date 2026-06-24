import os
from datetime import datetime

from sqlalchemy.orm import Session

from shared.models.db_models import Application, Job, Transaction, User, Wallet
from shared.services.mpesa import mpesa_client

PLATFORM_COMMISSION = 0.15


class MPesaService:
    async def initiate_job_payment(
        self,
        db: Session,
        job: Job,
        recruiter: User,
        phone_number: str | None = None,
    ) -> dict:
        amount = int(job.price or 0)
        if amount <= 0:
            raise ValueError("Job price must be greater than zero")

        transaction = Transaction(
            user_id=recruiter.id,
            amount=amount,
            type="job_payment",
            job_id=job.id,
            status="pending",
        )
        db.add(transaction)
        db.commit()
        db.refresh(transaction)

        callback_url = os.getenv(
            "MPESA_CALLBACK_URL",
            f"{os.getenv('API_BASE_URL', 'http://localhost:8003')}/payments/mpesa/callback",
        )

        if not os.getenv("MPESA_CONSUMER_KEY") or not os.getenv("MPESA_CONSUMER_SECRET"):
            transaction.mpesa_reference = f"LOCAL-{transaction.id}-{int(datetime.utcnow().timestamp())}"
            db.commit()
            return {
                "transaction_id": transaction.id,
                "status": transaction.status,
                "mpesa_reference": transaction.mpesa_reference,
                "message": "M-Pesa credentials are not configured; payment recorded as pending.",
            }

        response = await mpesa_client.stk_push(
            phone_number=phone_number or recruiter.phone_number,
            amount=amount,
            account_reference=f"Job-{job.id}",
            transaction_desc=f"Taskly job payment #{job.id}",
            callback_url=callback_url,
        )

        transaction.mpesa_reference = response.get("CheckoutRequestID") or response.get("MerchantRequestID")
        db.commit()

        return {
            "transaction_id": transaction.id,
            "status": transaction.status,
            "mpesa_reference": transaction.mpesa_reference,
            "mpesa_response": response,
        }

    def release_job_payment(self, db: Session, job: Job) -> dict:
        application = (
            db.query(Application)
            .filter(Application.job_id == job.id, Application.status == "accepted")
            .first()
        )
        if not application:
            raise ValueError("No accepted tasker application found for this job")

        tasker = db.query(User).filter(User.id == application.tasker_id).first()
        if not tasker:
            raise ValueError("Accepted tasker not found")

        gross_amount = float(job.price or 0)
        tasker_amount = round(gross_amount * (1 - PLATFORM_COMMISSION), 2)
        commission = round(gross_amount - tasker_amount, 2)

        wallet = db.query(Wallet).filter(Wallet.user_id == tasker.id).first()
        if not wallet:
            wallet = Wallet(user_id=tasker.id)
            db.add(wallet)

        wallet.balance = float(wallet.balance or 0) + tasker_amount
        wallet.available_withdrawal = float(wallet.available_withdrawal or 0) + tasker_amount
        wallet.total_earned = float(wallet.total_earned or 0) + tasker_amount
        wallet.updated_at = datetime.utcnow()

        transaction = Transaction(
            user_id=tasker.id,
            amount=tasker_amount,
            type="payment_release",
            job_id=job.id,
            status="released",
        )
        db.add(transaction)

        job.status = "completed"
        tasker.total_jobs = int(tasker.total_jobs or 0) + 1
        db.commit()
        db.refresh(transaction)

        return {
            "transaction_id": transaction.id,
            "job_id": job.id,
            "tasker_id": tasker.id,
            "gross_amount": gross_amount,
            "tasker_amount": tasker_amount,
            "platform_commission": commission,
            "status": "released",
        }


mpesa_service = MPesaService()
