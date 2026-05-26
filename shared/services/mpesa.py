import os
import base64
from datetime import datetime
import httpx
from dotenv import load_dotenv

load_dotenv()

MPESA_CONSUMER_KEY = os.getenv("MPESA_CONSUMER_KEY", "")
MPESA_CONSUMER_SECRET = os.getenv("MPESA_CONSUMER_SECRET", "")
MPESA_SHORTCODE = os.getenv("MPESA_SHORTCODE", "")
MPESA_PASSKEY = os.getenv("MPESA_PASSKEY", "")
MPESA_ENV = os.getenv("MPESA_ENV", "sandbox")

MPESA_BASE_URL = "https://sandbox.safaricom.co.ke" if MPESA_ENV == "sandbox" else "https://api.safaricom.co.ke"


class MPesaClient:
    def __init__(self):
        self.base_url = MPESA_BASE_URL
        self.consumer_key = MPESA_CONSUMER_KEY
        self.consumer_secret = MPESA_CONSUMER_SECRET
        self.shortcode = MPESA_SHORTCODE
        self.passkey = MPESA_PASSKEY

    async def get_access_token(self) -> str:
        auth_string = f"{self.consumer_key}:{self.consumer_secret}"
        encoded = base64.b64encode(auth_string.encode()).decode()
        headers = {"Authorization": f"Basic {encoded}"}
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/oauth/v1/generate?grant_type=client_credentials", headers=headers)
            response.raise_for_status()
            return response.json()["access_token"]

    async def simulate_stk_push(self, phone_number: str, amount: int, account_reference: str, transaction_desc: str) -> dict:
        token = await self.get_access_token()
        timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
        password = base64.b64encode(f"{self.shortcode}{self.passkey}{timestamp}".encode()).decode()
        payload = {
            "BusinessShortCode": self.shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": amount,
            "PartyA": phone_number,
            "PartyB": self.shortcode,
            "PhoneNumber": phone_number,
            "CallBackURL": os.getenv("MPESA_CALLBACK_URL", "https://example.com/mpesa/callback"),
            "AccountReference": account_reference,
            "TransactionDesc": transaction_desc,
        }
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        async with httpx.AsyncClient() as client:
            response = await client.post(f"{self.base_url}/mpesa/stkpush/v1/processrequest", json=payload, headers=headers)
            response.raise_for_status()
            return response.json()

    async def b2c_payment(self, phone_number: str, amount: int, remarks: str = "Taskly payout") -> dict:
        token = await self.get_access_token()
        payload = {
            "InitiatorName": os.getenv("MPESA_INITIATOR_NAME", ""),
            "SecurityCredential": os.getenv("MPESA_SECURITY_CREDENTIAL", ""),
            "CommandID": "BusinessPayment",
            "Amount": amount,
            "PartyA": self.shortcode,
            "PartyB": phone_number,
            "Remarks": remarks,
            "QueueTimeOutURL": os.getenv("MPESA_QUEUE_TIMEOUT_URL", "https://example.com/mpesa/timeout"),
            "ResultURL": os.getenv("MPESA_RESULT_URL", "https://example.com/mpesa/result"),
            "Occasion": "Taskly Withdrawal",
        }
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        async with httpx.AsyncClient() as client:
            response = await client.post(f"{self.base_url}/mpesa/b2c/v1/paymentrequest", json=payload, headers=headers)
            response.raise_for_status()
            return response.json()
