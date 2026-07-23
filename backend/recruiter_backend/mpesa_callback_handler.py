import json
from sqlalchemy.orm import Session
from shared.models.transaction import Transaction, TransactionStatus, Withdrawal
from shared.models.job import Job, JobStatus
from shared.models.user import Wallet, Tasker
from shared.services.escrow import escrow
from shared.services.notifications import send_push
from datetime import datetime


class MpesaCallbackHandler:
     @staticmethod
     def handle_payment_callback(callback_data: dict, db: Session) -> dict:
         """
         Handle M-Pesa callback for STK Push payment
         
         Expected callback format from M-Pesa:
         {
             "Body": {
                 "stkCallback": {
                     "MerchantRequestID": "...",
                     "CheckoutRequestID": "...",
                     "ResultCode": 0,
                     "ResultDesc": "The service request has been processed successfully.",
                     "CallbackMetadata": {
                         "Item": [
                             {"Name": "Amount", "Value": 1.0},
                             {"Name": "MpesaReceiptNumber", "Value": "LHG31AA5IF"},
                             {"Name": "TransactionDate", "Value": 20231214102030},
                             {"Name": "PhoneNumber", "Value": 254712345678}
                         ]
                     }
                 }
             }
         }
         """
         try:
             body = callback_data.get("Body", {})
             stk_callback = body.get("stkCallback", {})
             
             checkout_id = stk_callback.get("CheckoutRequestID")
             result_code = stk_callback.get("ResultCode")
             
             transaction = db.query(Transaction).filter(Transaction.mpesa_transaction_id == checkout_id).first()
             if not transaction:
                 return {"success": False, "error": "Transaction not found for checkout ID"}
 
             if result_code == 0:
                 callback_meta = stk_callback.get("CallbackMetadata", {})
                 items = {item["Name"]: item["Value"] for item in callback_meta.get("Item", [])}
                 mpesa_receipt = items.get("MpesaReceiptNumber")
                 
                 escrow.confirm_payment(db, transaction.id, mpesa_receipt)
                 return {"success": True, "message": "Payment confirmed"}
             else:
                 transaction.status = TransactionStatus.FAILED
                 db.commit()
                 return {"success": False, "message": "Payment failed", "result_code": result_code}
         
         except Exception as e:
             print(f"Callback processing error: {str(e)}")
             return {"success": False, "error": str(e)}
 
     @staticmethod
     def handle_withdrawal_callback(callback_data: dict, db: Session) -> dict:
         """Handle M-Pesa callback for B2C withdrawal"""
         try:
             result = callback_data.get("Result", {})
             result_code = result.get("ResultCode")
             conversation_id = result.get("ConversationID")
 
             withdrawal = db.query(Withdrawal).filter_by(mpesa_conversation_id=conversation_id).first()
             if not withdrawal:
                 return {"success": False, "error": "Withdrawal not found"}
 
             wallet = db.query(Wallet).filter_by(tasker_id=withdrawal.tasker_id).first()
 
             if result_code == 0:
                 withdrawal.status = "completed"
                 withdrawal.mpesa_result_code = str(result_code)
                 withdrawal.completed_at = datetime.utcnow()
 
                 wallet.pending_withdrawals -= withdrawal.amount
                 wallet.total_withdrawn += withdrawal.amount
 
                 send_push(
                     user_id=withdrawal.tasker_id, user_type="tasker",
                     title="Withdrawal Successful! 💰",
                     body=f"KES {withdrawal.amount/100:.2f} has been sent to your M-Pesa",
                     db=db
                 )
             else:
                 withdrawal.status = "failed"
                 withdrawal.mpesa_result_code = str(result_code)
 
                 wallet.available_balance += withdrawal.amount
                 wallet.pending_withdrawals -= withdrawal.amount
 
                 send_push(
                     user_id=withdrawal.tasker_id, user_type="tasker",
                     title="Withdrawal Failed",
                     body=f"Your withdrawal of KES {withdrawal.amount/100:.2f} failed. Amount refunded.",
                     db=db
                 )
             
             db.commit()
             return {"success": True, "message": "Withdrawal callback processed"}
 
         except Exception as e:
             return {"success": False, "error": str(e)}
 
 
mpesa_callback_handler = MpesaCallbackHandler()