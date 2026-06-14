from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
import os

class EmailService:
    def __init__(self):
        self.sg = SendGridAPIClient(os.getenv("SENDGRID_API_KEY"))
        self.from_email = "noreply@taskly.com"
    
    def send_application_received(self, recruiter_email: str, job_title: str, tasker_name: str):
        """Notify recruiter of new application"""
        message = Mail(
            from_email=self.from_email,
            to_emails=recruiter_email,
            subject=f"New Application: {job_title}",
            html_content=f"""
            <h2>New Application Received!</h2>
            <p>{tasker_name} has applied for your job: <strong>{job_title}</strong></p>
            <p><a href="https://taskly.com/app/applications">View Application</a></p>
            """
        )
        self.sg.send(message)
    
    def send_job_awarded(self, tasker_email: str, job_title: str, price: int):
        """Notify tasker they got the job"""
        message = Mail(
            from_email=self.from_email,
            to_emails=tasker_email,
            subject=f"You Got the Job! {job_title}",
            html_content=f"""
            <h2>Congratulations! 🎉</h2>
            <p>You have been selected for: <strong>{job_title}</strong></p>
            <p>Price: <strong>{price} KES</strong></p>
            <p><a href="https://taskly.com/app/jobs/{job_title}">View Job Details</a></p>
            """
        )
        self.sg.send(message)
    
    def send_payment_released(self, tasker_email: str, amount: int, job_title: str):
        """Notify tasker payment was released"""
        message = Mail(
            from_email=self.from_email,
            to_emails=tasker_email,
            subject=f"Payment Released: {amount} KES",
            html_content=f"""
            <h2>Payment Released! 💰</h2>
            <p>Your payment for <strong>{job_title}</strong> has been released.</p>
            <p>Amount: <strong>{amount} KES</strong> (85% after commission)</p>
            <p>Check your M-Pesa account.</p>
            """
        )
        self.sg.send(message)
    
    def send_image_verification_passed(self, tasker_email: str, recruiter_email: str, 
                                      job_title: str, match_percentage: int):
        """Notify both parties work quality verified"""
        for email in [tasker_email, recruiter_email]:
            message = Mail(
                from_email=self.from_email,
                to_emails=email,
                subject=f"Work Quality Verified: {job_title}",
                html_content=f"""
                <h2>Work Quality Verified ✅</h2>
                <p>Before/after images matched at <strong>{match_percentage}%</strong></p>
                <p>Payment will be released shortly.</p>
                """
            )
            self.sg.send(message)

# Usage in endpoints
email_service = EmailService()
