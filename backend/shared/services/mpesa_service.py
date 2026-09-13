import requests
import json
import os
from datetime import datetime
from base64 import b64encode
from dotenv import load_dotenv

load_dotenv()

class MpesaService:
    def __init__(self):
        self.consumer_key = os.getenv("MPESA_CONSUMER_KEY")
        self.consumer_secret = os.getenv("MPESA_CONSUMER_SECRET")
        self.shortcode = os.getenv("MPESA_SHORTCODE", "174379")
        self.passkey = os.getenv("MPESA_PASSKEY")
        self.environment = os.getenv("MPESA_ENVIRONMENT", "sandbox")
        self.initiator_name = os.getenv("MPESA_INITIATOR_NAME", "testapi")
        self.security_credential = os.getenv("MPESA_SECURITY_CREDENTIAL")
        
        # Sandbox URLs
        self.base_url = "https://sandbox.safaricom.co.ke" if self.environment == "sandbox" else "https://api.safaricom.co.ke"
        self.auth_url = f"{self.base_url}/oauth/v1/generate?grant_type=client_credentials"
        self.stkpush_url = f"{self.base_url}/mpesa/stkpush/v1/processrequest"
        self.b2c_url = f"{self.base_url}/mpesa/b2c/v1/paymentrequest"
        self.callback_url = os.getenv("MPESA_CALLBACK_URL", "https://your-domain.com/mpesa/callback")
    
    def get_access_token(self) -> str:
        """Get M-Pesa access token"""
        try:
            auth_string = f"{self.consumer_key}:{self.consumer_secret}"
            encoded_auth = b64encode(auth_string.encode()).decode()
            
            headers = {
                "Authorization": f"Basic {encoded_auth}",
                "Content-Type": "application/json"
            }
            
            response = requests.get(self.auth_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            return response.json().get("access_token")
        except Exception as e:
            print(f"Error getting access token: {str(e)}")
            return None
    
    def initiate_stk_push(self, phone_number: str, amount: float, job_id: int, job_title: str) -> dict:
        """
        Initiate STK Push for payment
        This prompts user on their phone to enter M-Pesa PIN
        """
        try:
            access_token = self.get_access_token()
            if not access_token:
                return {
                    "success": False,
                    "message": "Failed to get access token",
                    "checkpoint_id": None
                }
            
            # Format phone number (remove +, add 254)
            if phone_number.startswith("+"):
                phone_number = phone_number[1:]
            if phone_number.startswith("0"):
                phone_number = "254" + phone_number[1:]
            elif not phone_number.startswith("254"):
                phone_number = "254" + phone_number
            
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            password_string = f"{self.shortcode}{self.passkey}{timestamp}"
            password = b64encode(password_string.encode()).decode()
            
            payload = {
                "BusinessShortCode": self.shortcode,
                "Password": password,
                "Timestamp": timestamp,
                "TransactionType": "CustomerPayBillOnline",
                "Amount": int(amount),
                "PartyA": phone_number,
                "PartyB": self.shortcode,
                "PhoneNumber": phone_number,
                "CallBackURL": self.callback_url,
                "AccountReference": f"Job-{job_id}",
                "TransactionDesc": job_title[:49]  # Max 49 chars
            }
            
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            response = requests.post(
                self.stkpush_url,
                json=payload,
                headers=headers,
                timeout=10
            )
            
            result = response.json()
            
            if result.get("ResponseCode") == "0":
                return {
                    "success": True,
                    "message": "STK Push sent. User will receive prompt on phone.",
                    "checkpoint_id": result.get("CheckoutRequestID"),
                    "request_id": result.get("RequestId")
                }
            else:
                return {
                    "success": False,
                    "message": result.get("ResponseDescription", "Failed to initiate payment"),
                    "checkpoint_id": None
                }
        except Exception as e:
            return {
                "success": False,
                "message": f"Error: {str(e)}",
                "checkpoint_id": None
            }
    
    def process_b2c_withdrawal(self, phone_number: str, amount: float, worker_name: str) -> dict:
        """
        Send money to worker's M-Pesa account (B2C - Business to Customer)
        """
        try:
            access_token = self.get_access_token()
            if not access_token:
                return {
                    "success": False,
                    "message": "Failed to get access token",
                    "transaction_id": None
                }
            
            # Format phone number
            if phone_number.startswith("+"):
                phone_number = phone_number[1:]
            if phone_number.startswith("0"):
                phone_number = "254" + phone_number[1:]
            elif not phone_number.startswith("254"):
                phone_number = "254" + phone_number
            
            payload = {
                "InitiatorName": self.initiator_name,
                "SecurityCredential": self.security_credential,
                "CommandID": "SalaryPayment",
                "Amount": int(amount),
                "PartyA": self.shortcode,
                "PartyB": phone_number,
                "Remarks": f"Taskly payment for {worker_name}",
                "QueueTimeOutURL": f"{self.callback_url}?type=timeout",
                "ResultURL": f"{self.callback_url}?type=result"
            }
            
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            response = requests.post(
                self.b2c_url,
                json=payload,
                headers=headers,
                timeout=10
            )
            
            result = response.json()
            
            if result.get("ResponseCode") == "0":
                return {
                    "success": True,
                    "message": "Withdrawal initiated. Money will be sent to phone.",
                    "transaction_id": result.get("ConversationID"),
                    "request_id": result.get("OriginatorConversationID")
                }
            else:
                return {
                    "success": False,
                    "message": result.get("ResponseDescription", "Withdrawal failed"),
                    "transaction_id": None
                }
        except Exception as e:
            return {
                "success": False,
                "message": f"Error: {str(e)}",
                "transaction_id": None
            }
    
    def query_stk_push_status(self, checkout_request_id: str) -> dict:
        """Query status of STK Push"""
        try:
            access_token = self.get_access_token()
            if not access_token:
                return {"success": False, "status": "unknown"}
            
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            password_string = f"{self.shortcode}{self.passkey}{timestamp}"
            password = b64encode(password_string.encode()).decode()
            
            payload = {
                "BusinessShortCode": self.shortcode,
                "Password": password,
                "Timestamp": timestamp,
                "CheckoutRequestID": checkout_request_id
            }
            
            headers = {
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json"
            }
            
            query_url = f"{self.base_url}/mpesa/stkpushquery/v1/query"
            
            response = requests.post(
                query_url,
                json=payload,
                headers=headers,
                timeout=10
            )
            
            result = response.json()
            status = result.get("ResultCode") == "0"
            
            return {
                "success": status,
                "status": "completed" if status else "pending",
                "receipt": result.get("MpesaReceiptNumber"),
                "result_description": result.get("ResultDesc")
            }
        except Exception as e:
            return {
                "success": False,
                "status": "error",
                "message": str(e)
            }
    
    def validate_phone(self, phone_number: str) -> bool:
        """Validate Kenyan phone number"""
        # Remove spaces, +, and dashes
        phone = phone_number.replace(" ", "").replace("+", "").replace("-", "")
        
        # Must be 12 digits (254XXXXXXXXX) or 10 digits (07XXXXXXXX or 01XXXXXXXX)
        if phone.startswith("254") and len(phone) == 12:
            return True
        if (phone.startswith("0") or phone.startswith("1")) and len(phone) == 10:
            return True
        return False