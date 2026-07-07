import logging
from sqlalchemy.orm import Session
from shared.models.db_models import Transaction, Job, Wallet

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MpesaCallbackHandler:
    """
    Handles M-Pesa STK Push and B2C callbacks.
    """
    def __init__(self, db: Session):
        self.db = db

    def handle_payment_callback(self, callback_data: dict) -> dict:
        """
        Processes the callback from a C2B (Customer to Business) payment via STK Push.
        This is for when a recruiter pays for a job.
        """
        logger.info(f"Received M-Pesa payment callback: {callback_data}")

        try:
            stk_callback = callback_data.get("Body", {}).get("stkCallback", {})
            result_code = stk_callback.get("ResultCode")
            checkout_request_id = stk_callback.get("CheckoutRequestID")

            # Find the transaction using the CheckoutRequestID
            transaction = self.db.query(Transaction).filter(
                Transaction.mpesa_transaction_id == checkout_request_id,
                Transaction.status == "pending"
            ).first()

            if not transaction:
                logger.error(f"Transaction not found for CheckoutRequestID: {checkout_request_id}")
                return {"ResultCode": 1, "ResultDesc": "Transaction not found"}

            if result_code == 0:
                # Payment was successful
                callback_metadata = stk_callback.get("CallbackMetadata", {}).get("Item", [])
                mpesa_receipt = next((item['Value'] for item in callback_metadata if item['Name'] == 'MpesaReceiptNumber'), None)

                transaction.status = "completed"
                transaction.mpesa_receipt_number = mpesa_receipt

                # Update job status to 'paid'
                job = self.db.query(Job).filter(Job.id == transaction.job_id).first()
                if job:
                    job.status = "paid"
                    logger.info(f"Job {job.id} status updated to 'paid'.")

                self.db.commit()
                logger.info(f"Successfully processed payment for transaction {transaction.id}")

            else:
                # Payment failed or was cancelled
                result_desc = stk_callback.get("ResultDesc", "Payment failed")
                transaction.status = "failed"
                transaction.failure_reason = result_desc
                self.db.commit()
                logger.warning(f"Payment failed for transaction {transaction.id}. Reason: {result_desc}")

            return {"ResultCode": 0, "ResultDesc": "Callback processed successfully"}

        except Exception as e:
            logger.error(f"Error processing payment callback: {e}", exc_info=True)
            # In case of an error, we still tell M-Pesa we received it to prevent retries.
            return {"ResultCode": 0, "ResultDesc": "Accepted, but internal error occurred"}

    def handle_withdrawal_callback(self, callback_data: dict) -> dict:
        """
        Processes the callback from a B2C (Business to Customer) payment.
        This is for when a tasker withdraws funds to their M-Pesa.
        """
        logger.info(f"Received M-Pesa withdrawal callback: {callback_data}")

        try:
            result = callback_data.get("Result", {})
            result_code = result.get("ResultCode")
            conversation_id = result.get("ConversationID")

            # Find the transaction using the ConversationID
            transaction = self.db.query(Transaction).filter(
                Transaction.mpesa_transaction_id == conversation_id,
                Transaction.status == "processing"
            ).first()

            if not transaction:
                logger.error(f"Withdrawal transaction not found for ConversationID: {conversation_id}")
                return {"ResultCode": 1, "ResultDesc": "Transaction not found"}

            if result_code == 0:
                transaction.status = "completed"
                logger.info(f"Withdrawal successful for transaction {transaction.id}")
            else:
                transaction.status = "failed"
                transaction.failure_reason = result.get("ResultDesc", "Withdrawal failed")
                logger.warning(f"Withdrawal failed for transaction {transaction.id}")

            self.db.commit()
            return {"ResultCode": 0, "ResultDesc": "Callback processed successfully"}
        except Exception as e:
            logger.error(f"Error processing withdrawal callback: {e}", exc_info=True)
            return {"ResultCode": 0, "ResultDesc": "Accepted, but internal error occurred"}