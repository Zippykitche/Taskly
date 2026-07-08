import schedule
import time
from datetime import datetime
from threading import Thread
from sqlalchemy.orm import Session
from shared.database import SessionLocal
from shared.services.daily_report_service import DailyReportService
from shared.services.email_service import EmailService
import os
from dotenv import load_dotenv

load_dotenv()

# Your emails
TJAY_EMAIL = "tjayearl@gmail.com"
ZIPPORAH_EMAIL = os.getenv("ZIPPORAH_EMAIL", "zipporah@example.com")

email_service = EmailService()

def send_daily_report():
    """
    Generate daily report and send to Tjay and Zipporah
    Runs at 11:59 PM UTC
    """
    try:
        db = SessionLocal()
        
        # Get yesterday's date for report
        from datetime import datetime, timedelta
        yesterday = (datetime.utcnow() - timedelta(days=1)).strftime("%Y-%m-%d")
        
        print(f"[{datetime.utcnow()}] Generating daily report for {yesterday}...")
        
        # Generate PDF
        report = DailyReportService.generate_daily_report_pdf(
            db=db,
            report_date=yesterday,
            tjay_email=TJAY_EMAIL,
            zipporah_email=ZIPPORAH_EMAIL
        )
        
        if not report["success"]:
            print(f"Error generating report: {report.get('error')}")
            return
        
        # Get summary
        summary = DailyReportService.get_daily_summary(db, yesterday)
        
        # Email to Tjay
        tjay_result = send_report_email(
            to_email=TJAY_EMAIL,
            recipient_name="Tjay",
            report=report,
            summary=summary
        )
        
        print(f"Tjay email result: {tjay_result}")
        
        # Email to Zipporah
        zipporah_result = send_report_email(
            to_email=ZIPPORAH_EMAIL,
            recipient_name="Zipporah",
            report=report,
            summary=summary
        )
        
        print(f"Zipporah email result: {zipporah_result}")
        
        db.close()
        print(f"[{datetime.utcnow()}] Daily report sent successfully!")
        
    except Exception as e:
        print(f"Error in send_daily_report: {str(e)}")

def send_report_email(to_email: str, recipient_name: str, report: dict, summary: dict) -> dict:
    """Send report email"""
    try:
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; color: #333;">
            <div style="max-width: 600px; margin: 0 auto;">
                <div style="background-color: #0C1F3E; color: white; padding: 20px; text-align: center;">
                    <h1>TASKLY Daily Earnings Report</h1>
                    <p>Report Date: {summary.get('report_date')}</p>
                </div>
                
                <div style="padding: 20px; border: 1px solid #ddd;">
                    <h2>Hi {recipient_name},</h2>
                    
                    <p>Your daily earnings report for <strong>{summary.get('report_date')}</strong> is ready.</p>
                    
                    <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                        <h3 style="color: #0C1F3E; margin-top: 0;">Daily Summary</h3>
                        <table style="width: 100%;">
                            <tr>
                                <td style="padding: 8px;"><strong>Total Jobs:</strong></td>
                                <td style="padding: 8px; text-align: right;">{summary.get('total_jobs')}</td>
                            </tr>
                            <tr style="background-color: #fff;">
                                <td style="padding: 8px;"><strong>Gross Earnings:</strong></td>
                                <td style="padding: 8px; text-align: right;">KES {summary.get('gross_total'):,.2f}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px;"><strong>Platform Commission (15%):</strong></td>
                                <td style="padding: 8px; text-align: right;">KES {summary.get('commission_total'):,.2f}</td>
                            </tr>
                            <tr style="background-color: #fff;">
                                <td style="padding: 8px;"><strong>Taxes & Deductions:</strong></td>
                                <td style="padding: 8px; text-align: right;">KES {summary.get('tax_total'):,.2f}</td>
                            </tr>
                            <tr style="background-color: #F0F0F0; font-weight: bold; border-top: 2px solid #0C1F3E;">
                                <td style="padding: 8px;">NET EARNINGS:</td>
                                <td style="padding: 8px; text-align: right;">KES {summary.get('net_total'):,.2f}</td>
                            </tr>
                        </table>
                    </div>
                    
                    <p style="color: #666; font-size: 12px;">
                        A detailed PDF report with individual transaction receipts is attached to this email.
                    </p>
                    
                    <p style="color: #666; margin-top: 20px;">
                        <strong>Next Steps:</strong><br>
                        Review your receipts • Verify amounts • Process withdrawals
                    </p>
                    
                    <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
                    
                    <p style="font-size: 12px; color: #999;">
                        This is an automatically generated report sent daily at 11:59 PM UTC.<br>
                        For support, contact support@taskly.com
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
        
        result = email_service._send_email(
        result = email_service._send(
            to_email=to_email,
            subject=f"Taskly Daily Report - {summary.get('report_date')}",
            html_content=html_body
        )
        
        return result
    
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

def start_scheduler():
    """
    Start the scheduler in a background thread
    Schedule daily report at 11:59 PM UTC
    """
    schedule.every().day.at("23:59").do(send_daily_report)
    
    def run_scheduler():
        while True:
            try:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
            except Exception as e:
                print(f"Scheduler error: {str(e)}")
                time.sleep(60)
    
    # Start scheduler in background thread
    scheduler_thread = Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()
    print("✅ Daily report scheduler started (11:59 PM UTC)")

# Manual function to trigger report (for testing)
def trigger_daily_report(report_date: str = None):
    """Manually trigger daily report generation"""
    try:
        db = SessionLocal()
        
        if report_date is None:
            from datetime import datetime, timedelta
            report_date = (datetime.utcnow() - timedelta(days=1)).strftime("%Y-%m-%d")
        
        print(f"Generating report for {report_date}...")
        
        report = DailyReportService.generate_daily_report_pdf(
            db=db,
            report_date=report_date,
            tjay_email=TJAY_EMAIL,
            zipporah_email=ZIPPORAH_EMAIL
        )
        
        if report["success"]:
            print(f"✅ Report generated: {report['file_path']}")
            print(f"   Total Jobs: {report['total_jobs']}")
            print(f"   Gross: KES {report['gross_total']:,.2f}")
            print(f"   Commission: KES {report['commission_total']:,.2f}")
            print(f"   Tax: KES {report['tax_total']:,.2f}")
            print(f"   Net: KES {report['net_total']:,.2f}")
        else:
            print(f"❌ Error: {report.get('error')}")
        
        db.close()
        return report
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    # Test the scheduler
    print("Starting scheduler... Press Ctrl+C to stop")
    start_scheduler()
    
    # Keep the main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Scheduler stopped")
