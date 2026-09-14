import os
import smtplib
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import httpx

logger = logging.getLogger("taskly.email_service")


class EmailService:
    def __init__(self):
        # 1. SMTP Settings (Gmail, Brevo, or custom SMTP)
        self.smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USER") or os.getenv("EMAIL_USER")
        self.smtp_password = os.getenv("SMTP_PASSWORD") or os.getenv("EMAIL_PASSWORD")

        # 2. Resend API Settings
        self.resend_api_key = os.getenv("RESEND_API_KEY")

        # 3. SendGrid API Settings
        self.sendgrid_api_key = os.getenv("SENDGRID_API_KEY")
        if self.sendgrid_api_key and "YOUR_KEY" in self.sendgrid_api_key:
            self.sendgrid_api_key = None  # ignore default placeholder

        # Sender identity
        self.from_email = (
            os.getenv("SMTP_FROM_EMAIL")
            or os.getenv("SENDGRID_FROM_EMAIL")
            or self.smtp_user
            or "noreply@taskly.com"
        )
        self.from_name = os.getenv("EMAIL_FROM_NAME", "Taskly")

    def _send(self, to_email: str, subject: str, html_content: str) -> bool:
        if not to_email:
            return False

        # Provider 1: Resend API (via HTTP)
        if self.resend_api_key:
            try:
                with httpx.Client(timeout=10.0) as client:
                    resp = client.post(
                        "https://api.resend.com/emails",
                        headers={
                            "Authorization": f"Bearer {self.resend_api_key}",
                            "Content-Type": "application/json",
                        },
                        json={
                            "from": f"{self.from_name} <{self.from_email}>",
                            "to": [to_email],
                            "subject": subject,
                            "html": html_content,
                        },
                    )
                    if resp.status_code in (200, 201):
                        logger.info(f"Email sent via Resend to {to_email}: {subject}")
                        print(f"📧 [Resend] Email sent to {to_email}: {subject}")
                        return True
                    else:
                        logger.error(f"Resend API error ({resp.status_code}): {resp.text}")
                        print(f"⚠️ [Resend Error]: {resp.text}")
            except Exception as e:
                logger.error(f"Failed to send email via Resend: {e}")
                print(f"⚠️ [Resend Exception]: {e}")

        # Provider 2: SendGrid API (via HTTP)
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
                        logger.info(f"Email sent via SendGrid to {to_email}: {subject}")
                        print(f"📧 [SendGrid] Email sent to {to_email}: {subject}")
                        return True
                    else:
                        logger.error(f"SendGrid API error ({resp.status_code}): {resp.text}")
                        print(f"⚠️ [SendGrid Error]: {resp.text}")
            except Exception as e:
                logger.error(f"Failed to send email via SendGrid: {e}")
                print(f"⚠️ [SendGrid Exception]: {e}")

        # Provider 3: Standard SMTP (Gmail, Brevo, custom SMTP)
        if self.smtp_user and self.smtp_password:
            try:
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject
                msg["From"] = f"{self.from_name} <{self.from_email}>"
                msg["To"] = to_email

                part = MIMEText(html_content, "html")
                msg.attach(part)

                server = smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=12)
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.sendmail(self.from_email, to_email, msg.as_string())
                server.quit()
                logger.info(f"Email sent via SMTP to {to_email}: {subject}")
                print(f"📧 [SMTP] Email sent to {to_email}: {subject}")
                return True
            except Exception as e:
                logger.error(f"Failed to send email via SMTP: {e}")
                print(f"⚠️ [SMTP Error]: {e}")

        logger.warning(
            f"No email credentials configured. Email to {to_email} was skipped. "
            "Please configure SMTP_USER/SMTP_PASSWORD or RESEND_API_KEY."
        )
        print(f"ℹ️ [Email Skipped] No credentials configured to send email to {to_email}.")
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
