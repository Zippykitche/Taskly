import os
import smtplib
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import httpx
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("taskly.email_service")


class EmailService:
    def __init__(self):
        self.last_log = None
        self._refresh_config()

    def _refresh_config(self):
        """Refreshes credentials dynamically from environment variables."""
        self.smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
        try:
            self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        except (ValueError, TypeError):
            self.smtp_port = 587

        self.smtp_user = os.getenv("SMTP_USER") or os.getenv("EMAIL_USER")
        raw_password = os.getenv("SMTP_PASSWORD") or os.getenv("EMAIL_PASSWORD")
        if raw_password:
            clean = raw_password.strip()
            # Google App passwords often include spaces: 'xxxx yyyy zzzz wwww'
            if len(clean.replace(" ", "")) == 16:
                self.smtp_password = clean.replace(" ", "")
            else:
                self.smtp_password = clean
        else:
            self.smtp_password = None

        self.resend_api_key = os.getenv("RESEND_API_KEY")
        self.brevo_api_key = os.getenv("BREVO_API_KEY")
        self.sendgrid_api_key = os.getenv("SENDGRID_API_KEY")
        if self.sendgrid_api_key and "YOUR_KEY" in self.sendgrid_api_key:
            self.sendgrid_api_key = None

        resend_default_from = "onboarding@resend.dev" if self.resend_api_key else "noreply@taskly.com"
        self.from_email = (
            os.getenv("SMTP_FROM_EMAIL")
            or os.getenv("RESEND_FROM_EMAIL")
            or os.getenv("SENDGRID_FROM_EMAIL")
            or self.smtp_user
            or resend_default_from
        )
        self.from_name = os.getenv("EMAIL_FROM_NAME", "Taskly")

    def _send(self, to_email: str, subject: str, html_content: str) -> bool:
        if not to_email:
            return False

        self._refresh_config()
        errors = []

        # Provider 1: Brevo REST API (HTTPS port 443 - NEVER blocked by cloud free tiers)
        if self.brevo_api_key:
            try:
                brevo_sender_email = os.getenv("BREVO_FROM_EMAIL") or self.smtp_user or "taskly89@gmail.com"
                with httpx.Client(timeout=10.0) as client:
                    resp = client.post(
                        "https://api.brevo.com/v3/smtp/email",
                        headers={
                            "api-key": self.brevo_api_key,
                            "Content-Type": "application/json",
                            "Accept": "application/json",
                        },
                        json={
                            "sender": {
                                "name": self.from_name,
                                "email": brevo_sender_email,
                            },
                            "to": [{"email": to_email}],
                            "subject": subject,
                            "htmlContent": html_content,
                        },
                    )
                    if resp.status_code in (200, 201):
                        log_msg = f"Email sent via Brevo to {to_email}: {subject}"
                        logger.info(log_msg)
                        print(f"[Brevo] {log_msg}")
                        self.last_log = log_msg
                        return True
                    else:
                        err_msg = f"Brevo API error ({resp.status_code}): {resp.text}"
                        logger.error(err_msg)
                        errors.append(err_msg)
            except Exception as e:
                err_msg = f"Brevo Exception: {type(e).__name__} - {e}"
                logger.error(err_msg)
                errors.append(err_msg)

        # Provider 2: Standard SMTP (Gmail, Brevo, or custom SMTP)
        # Note: Render Free plan blocks ports 587, 465, and 25 at the firewall level.
        if self.smtp_user and self.smtp_password:
            from_sender = self.smtp_user if ("@gmail.com" in (self.smtp_user or "").lower()) else self.from_email
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"{self.from_name} <{from_sender}>"
            msg["To"] = to_email
            msg.attach(MIMEText(html_content, "html"))

            # Primary port with automatic fallback between 587 (STARTTLS) and 465 (SSL)
            ports_to_try = [self.smtp_port]
            alt_port = 465 if self.smtp_port == 587 else 587
            if alt_port not in ports_to_try:
                ports_to_try.append(alt_port)

            for port in ports_to_try:
                try:
                    if port == 465:
                        server = smtplib.SMTP_SSL(self.smtp_host, port, timeout=6)
                    else:
                        server = smtplib.SMTP(self.smtp_host, port, timeout=6)
                        server.starttls()
                    server.login(self.smtp_user, self.smtp_password)
                    server.sendmail(from_sender, to_email, msg.as_string())
                    server.quit()
                    log_msg = f"Email sent via SMTP (port {port}) from {from_sender} to {to_email}: {subject}"
                    logger.info(log_msg)
                    print(f"[SMTP] {log_msg}")
                    self.last_log = log_msg
                    return True
                except Exception as e:
                    err_msg = f"SMTP (port {port}) error: {type(e).__name__} - {e}"
                    logger.warning(err_msg)
                    print(f"[SMTP Warning] {err_msg}")
                    errors.append(err_msg)
        else:
            errors.append(f"SMTP skipped (configured: user={bool(self.smtp_user)}, pass={bool(self.smtp_password)})")

        # Provider 3: Resend API (via HTTP port 443)
        if self.resend_api_key:
            try:
                # If custom domain is not set, Resend sandbox requires onboarding@resend.dev
                resend_sender = os.getenv("RESEND_FROM_EMAIL") or "onboarding@resend.dev"
                with httpx.Client(timeout=10.0) as client:
                    resp = client.post(
                        "https://api.resend.com/emails",
                        headers={
                            "Authorization": f"Bearer {self.resend_api_key}",
                            "Content-Type": "application/json",
                        },
                        json={
                            "from": f"{self.from_name} <{resend_sender}>",
                            "to": [to_email],
                            "subject": subject,
                            "html": html_content,
                        },
                    )
                    if resp.status_code in (200, 201):
                        log_msg = f"Email sent via Resend to {to_email}: {subject}"
                        logger.info(log_msg)
                        print(f"[Resend] {log_msg}")
                        self.last_log = log_msg
                        return True
                    else:
                        err_msg = f"Resend API error ({resp.status_code}): {resp.text}"
                        logger.error(err_msg)
                        print(f"[Resend Error] {err_msg}")
                        errors.append(err_msg)
            except Exception as e:
                err_msg = f"Resend Exception: {type(e).__name__} - {e}"
                logger.error(err_msg)
                print(f"[Resend Exception] {err_msg}")
                errors.append(err_msg)

        # Provider 4: SendGrid API (via HTTP)
        if self.sendgrid_api_key:
            try:
                with httpx.Client(timeout=10.0) as client:
                    resp = client.post(
                        "https://api.sendgrid.com/v3/mail/send",
                        headers={
                            "Authorization": f"Bearer {self.sendgrid_api_key}",
                            "Content-Type": "application/json",
                        },
                        json={
                            "personalizations": [{"to": [{"email": to_email}]}],
                            "from": {"email": self.from_email, "name": self.from_name},
                            "subject": subject,
                            "content": [{"type": "text/html", "value": html_content}],
                        },
                    )
                    if resp.status_code in (200, 202):
                        log_msg = f"Email sent via SendGrid to {to_email}: {subject}"
                        logger.info(log_msg)
                        print(f"[SendGrid] {log_msg}")
                        self.last_log = log_msg
                        return True
                    else:
                        err_msg = f"SendGrid API error ({resp.status_code}): {resp.text}"
                        logger.error(err_msg)
                        print(f"[SendGrid Error] {err_msg}")
                        errors.append(err_msg)
            except Exception as e:
                err_msg = f"SendGrid Exception: {type(e).__name__} - {e}"
                logger.error(err_msg)
                print(f"[SendGrid Exception] {err_msg}")
                errors.append(err_msg)

        failure_detail = " | ".join(errors) if errors else "No providers configured"
        logger.warning(f"Email failed to {to_email}: {failure_detail}")
        print(f"[Email Failed] {failure_detail}")
        self.last_log = failure_detail
        return False

    def send_registration_email(self, to_email: str, full_name: str, user_type: str) -> bool:
        """Sends a welcome and account creation notification email immediately upon signup."""
        display_name = full_name.strip() if full_name else "User"
        role_title = "Tasker Pro" if user_type == "tasker" else "Client"
        subject = f"Welcome to Taskly - Account Created Successfully!"

        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; background-color: #f8fafc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
          <div style="max-width: 580px; margin: 30px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.06); border: 1px solid #e2e8f0;">
            <!-- Header Banner -->
            <div style="background: linear-gradient(135deg, #00B37E 0%, #008A61 100%); padding: 36px 30px; text-align: center;">
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 800; letter-spacing: -0.5px;">Taskly</h1>
              <p style="color: rgba(255,255,255,0.85); font-size: 14px; margin: 6px 0 0 0; font-weight: 500;">TaskRabbit for Africa</p>
            </div>

            <!-- Body Content -->
            <div style="padding: 32px 28px;">
              <h2 style="color: #0f172a; font-size: 21px; margin-top: 0; font-weight: 700;">Welcome to Taskly, {display_name}! 🎉</h2>
              
              <p style="color: #475569; font-size: 15px; line-height: 1.6; margin-top: 12px;">
                Your <strong>{role_title}</strong> account has been created successfully and is now active.
              </p>

              <!-- Status Card -->
              <div style="background-color: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 12px; padding: 18px 20px; margin: 24px 0;">
                <p style="color: #166534; font-size: 14.5px; margin: 0; font-weight: 700;">
                  ✓ Your Account is Active & Ready to Use
                </p>
                <p style="color: #15803d; font-size: 13.5px; margin: 6px 0 0 0; line-height: 1.5;">
                  You can sign in immediately using your registered email: <strong>{to_email}</strong>.
                </p>
              </div>

              <p style="color: #475569; font-size: 14.5px; line-height: 1.6;">
                Whether you're looking to hire trusted local service providers or earn money offering your skills, Taskly is here to connect you safely and reliably.
              </p>

              <div style="margin-top: 28px; padding-top: 20px; border-top: 1px solid #f1f5f9; color: #64748b; font-size: 13.5px;">
                <p style="margin: 0;">Need help or have questions? Simply reply to this email or visit our support team.</p>
              </div>
            </div>

            <!-- Footer -->
            <div style="background-color: #f8fafc; padding: 20px 28px; text-align: center; border-top: 1px solid #e2e8f0;">
              <p style="color: #94a3b8; font-size: 12px; margin: 0;">
                © 2026 Taskly. All rights reserved.
              </p>
            </div>
          </div>
        </body>
        </html>
        """
        return self._send(to_email, subject, html_content)

    def send_application_received(self, recruiter_email: str, job_title: str, tasker_name: str):
        """Notify recruiter of new application."""
        return self._send(
            recruiter_email,
            f"New Application: {job_title}",
            f"""
            <h2>New Application Received</h2>
            <p>{tasker_name} has applied for your job: <strong>{job_title}</strong></p>
            <p><a href="https://taskly.com/app/applications">View Application</a></p>
            """,
        )

    def send_job_awarded(self, tasker_email: str, job_title: str, price: int):
        """Notify tasker they got the job."""
        return self._send(
            tasker_email,
            f"You Got the Job: {job_title}",
            f"""
            <h2>Congratulations</h2>
            <p>You have been selected for: <strong>{job_title}</strong></p>
            <p>Price: <strong>{price} KES</strong></p>
            <p><a href="https://taskly.com/app/jobs/{job_title}">View Job Details</a></p>
            """,
        )

    def send_payment_released(self, tasker_email: str, amount: int, job_title: str):
        """Notify tasker payment was released."""
        return self._send(
            tasker_email,
            f"Payment Released: {amount} KES",
            f"""
            <h2>Payment Released</h2>
            <p>Your payment for <strong>{job_title}</strong> has been released.</p>
            <p>Amount: <strong>{amount} KES</strong> after commission.</p>
            <p>Check your M-Pesa account.</p>
            """,
        )

    def send_image_verification_passed(
        self,
        tasker_email: str,
        recruiter_email: str,
        job_title: str,
        match_percentage: int,
    ):
        """Notify both parties work quality verified."""
        sent = []
        for email in [tasker_email, recruiter_email]:
            sent.append(
                self._send(
                    email,
                    f"Work Quality Verified: {job_title}",
                    f"""
                    <h2>Work Quality Verified</h2>
                    <p>Before/after images matched at <strong>{match_percentage}%</strong>.</p>
                    <p>Payment will be released shortly.</p>
                    """,
                )
            )
        return any(sent)

    def send_dispute_opened(self, recipient_email: str, job_title: str, reason: str):
        """Notify a party that a dispute has been opened."""
        return self._send(
            recipient_email,
            f"Dispute Opened: {job_title}",
            f"""
            <h2>Dispute Opened</h2>
            <p>A dispute has been opened for <strong>{job_title}</strong>.</p>
            <p>Reason: <strong>{reason}</strong></p>
            """,
        )

    def send_rating_received(self, recipient_email: str, score: int, job_title: str):
        """Notify a user that they received a rating."""
        return self._send(
            recipient_email,
            f"New Rating: {score}/5",
            f"""
            <h2>New Rating Received</h2>
            <p>You received <strong>{score}/5</strong> for <strong>{job_title}</strong>.</p>
            """,
        )


email_service = EmailService()
