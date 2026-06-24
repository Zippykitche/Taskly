import os

try:
    from sendgrid import SendGridAPIClient
    from sendgrid.helpers.mail import Mail
except ImportError:
    SendGridAPIClient = None
    Mail = None


class EmailService:
    def __init__(self):
        api_key = os.getenv("SENDGRID_API_KEY")
        self.sg = SendGridAPIClient(api_key) if SendGridAPIClient and api_key else None
        self.from_email = os.getenv("TASKLY_FROM_EMAIL", "noreply@taskly.com")

    def _send(self, to_email: str, subject: str, html_content: str) -> bool:
        if not self.sg or not Mail or not to_email:
            return False

        message = Mail(
            from_email=self.from_email,
            to_emails=to_email,
            subject=subject,
            html_content=html_content,
        )
        try:
            self.sg.send(message)
            return True
        except Exception:
            return False

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
