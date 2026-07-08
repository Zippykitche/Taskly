from datetime import datetime, timedelta
import os

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy import and_
from sqlalchemy.orm import Session, joinedload

from shared.models.db_models import DailyReport, Receipt


class DailyReportService:
    @staticmethod
    def generate_daily_report_pdf(
        db: Session,
        report_date: str | None = None,
        tjay_email: str = "tjayearl@gmail.com",
        zipporah_email: str = "zipporah@taskly.com",
    ) -> dict:
        """Generate a daily earnings PDF report for receipts created on a date."""
        try:
            report_date = report_date or datetime.utcnow().strftime("%Y-%m-%d")
            report_datetime = datetime.strptime(report_date, "%Y-%m-%d")
            start_date = report_datetime
            end_date = report_datetime + timedelta(days=1)

            receipts = (
                db.query(Receipt)
                .options(joinedload(Receipt.job))
                .filter(
                    and_(
                        Receipt.created_at >= start_date,
                        Receipt.created_at < end_date,
                    )
                )
                .order_by(Receipt.created_at.asc())
                .all()
            )

            summary = _summarize_receipts(receipts)

            output_dir = os.getenv("TASKLY_REPORTS_DIR", "reports")
            os.makedirs(output_dir, exist_ok=True)
            file_path = os.path.join(output_dir, f"daily_report_{report_date}.pdf")

            doc = SimpleDocTemplate(file_path, pagesize=letter, topMargin=0.5 * inch)
            styles = getSampleStyleSheet()
            story = []

            title_style = ParagraphStyle(
                "ReportTitle",
                parent=styles["Heading1"],
                fontSize=22,
                textColor=colors.HexColor("#0C1F3E"),
                spaceAfter=6,
                alignment=TA_CENTER,
                fontName="Helvetica-Bold",
            )
            subtitle_style = ParagraphStyle(
                "ReportSubtitle",
                parent=styles["Normal"],
                fontSize=12,
                textColor=colors.grey,
                alignment=TA_CENTER,
                spaceAfter=20,
            )
            heading_style = ParagraphStyle(
                "ReportSectionHeading",
                parent=styles["Heading2"],
                fontSize=11,
                textColor=colors.white,
                spaceAfter=8,
                fontName="Helvetica-Bold",
                backColor=colors.HexColor("#0C1F3E"),
                leftIndent=6,
                rightIndent=6,
            )
            footer_style = ParagraphStyle(
                "ReportFooter",
                parent=styles["Normal"],
                fontSize=8,
                textColor=colors.grey,
                alignment=TA_CENTER,
            )

            story.append(Paragraph("TASKLY DAILY EARNINGS REPORT", title_style))
            story.append(
                Paragraph(
                    f"Report Date: {report_datetime.strftime('%A, %B %d, %Y')}",
                    subtitle_style,
                )
            )
            story.append(Spacer(1, 0.2 * inch))

            story.append(Paragraph("EXECUTIVE SUMMARY", heading_style))
            summary_table = Table(
                [
                    ["Metric", "Value"],
                    ["Total Jobs Completed", str(summary["total_jobs"])],
                    ["Gross Earnings", f"KES {summary['gross_total']:,.2f}"],
                    ["Platform Commission", f"KES {summary['commission_total']:,.2f}"],
                    ["Taxes & Deductions", f"KES {summary['tax_total']:,.2f}"],
                    ["Net Earnings", f"KES {summary['net_total']:,.2f}"],
                ],
                colWidths=[3 * inch, 3 * inch],
            )
            summary_table.setStyle(_summary_table_style())
            story.append(summary_table)
            story.append(Spacer(1, 0.3 * inch))

            if receipts:
                story.append(Paragraph("TRANSACTION DETAILS", heading_style))
                trans_data = [["Receipt Code", "Job", "Gross", "Commission", "Tax", "Net", "Status"]]
                for receipt in receipts:
                    job_title = receipt.job.title if receipt.job else "Unknown"
                    trans_data.append(
                        [
                            receipt.receipt_code,
                            job_title[:20],
                            f"KES {receipt.amount:,.0f}",
                            f"KES {receipt.commission_amount:,.0f}",
                            f"KES {receipt.tax_amount:,.0f}",
                            f"KES {receipt.net_amount:,.0f}",
                            receipt.status.upper(),
                        ]
                    )

                trans_table = Table(
                    trans_data,
                    colWidths=[
                        1.25 * inch,
                        1.05 * inch,
                        0.8 * inch,
                        0.9 * inch,
                        0.7 * inch,
                        0.8 * inch,
                        0.7 * inch,
                    ],
                )
                trans_table.setStyle(_transactions_table_style())
                story.append(trans_table)
                story.append(Spacer(1, 0.3 * inch))

            story.append(Paragraph("FINANCIAL BREAKDOWN", heading_style))
            gross_total = summary["gross_total"]
            breakdown_table = Table(
                [
                    ["Category", "Amount (KES)", "Percentage"],
                    ["Gross Earnings", f"{gross_total:,.2f}", "100%"],
                    ["Taskly Commission", f"{summary['commission_total']:,.2f}", _pct(summary["commission_total"], gross_total)],
                    ["Taxes & Deductions", f"{summary['tax_total']:,.2f}", _pct(summary["tax_total"], gross_total)],
                    ["Net Earnings", f"{summary['net_total']:,.2f}", _pct(summary["net_total"], gross_total)],
                ],
                colWidths=[2.5 * inch, 2.5 * inch, 1.5 * inch],
            )
            breakdown_table.setStyle(_breakdown_table_style())
            story.append(breakdown_table)
            story.append(Spacer(1, 0.4 * inch))

            story.append(
                Paragraph(
                    "This report is automatically generated daily. For inquiries, contact support@taskly.com",
                    footer_style,
                )
            )
            story.append(
                Paragraph(
                    f"Taskly 2026 | Report Generated: {datetime.utcnow():%Y-%m-%d %H:%M:%S UTC}",
                    footer_style,
                )
            )
            doc.build(story)

            _upsert_daily_report(db, report_date, file_path, summary)

            return {
                "success": True,
                "file_path": file_path,
                "report_date": report_date,
                "recipient_emails": [tjay_email, zipporah_email],
                "receipt_count": len(receipts),
                **summary,
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    @staticmethod
    def get_daily_summary(db: Session, report_date: str | None = None) -> dict:
        """Get daily earnings totals without generating a PDF."""
        try:
            report_date = report_date or datetime.utcnow().strftime("%Y-%m-%d")
            report_datetime = datetime.strptime(report_date, "%Y-%m-%d")
            receipts = (
                db.query(Receipt)
                .filter(
                    and_(
                        Receipt.created_at >= report_datetime,
                        Receipt.created_at < report_datetime + timedelta(days=1),
                    )
                )
                .all()
            )
            return {"success": True, "report_date": report_date, **_summarize_receipts(receipts)}
        except Exception as exc:
            return {"success": False, "error": str(exc)}


def _summarize_receipts(receipts: list[Receipt]) -> dict:
    return {
        "total_jobs": len(receipts),
        "gross_total": sum(receipt.amount or 0 for receipt in receipts),
        "commission_total": sum(receipt.commission_amount or 0 for receipt in receipts),
        "tax_total": sum(receipt.tax_amount or 0 for receipt in receipts),
        "net_total": sum(receipt.net_amount or 0 for receipt in receipts),
    }


def _upsert_daily_report(db: Session, report_date: str, file_path: str, summary: dict) -> None:
    daily_report = db.query(DailyReport).filter(DailyReport.report_date == report_date).first()
    if not daily_report:
        daily_report = DailyReport(report_date=report_date)
        db.add(daily_report)

    daily_report.total_jobs = summary["total_jobs"]
    daily_report.gross_earnings = summary["gross_total"]
    daily_report.total_commission = summary["commission_total"]
    daily_report.total_tax = summary["tax_total"]
    daily_report.net_earnings = summary["net_total"]
    daily_report.pdf_url = file_path
    db.flush()


def _pct(amount: float, total: float) -> str:
    return f"{(amount / total * 100) if total else 0:.1f}%"


def _summary_table_style() -> TableStyle:
    return TableStyle(
        [
            ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 11),
            ("FONT", (0, 1), (-1, -1), "Helvetica", 10),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0C1F3E")),
            ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#F0F0F0")),
            ("FONT", (0, -1), (-1, -1), "Helvetica-Bold", 10),
            ("ALIGN", (0, 0), (-1, -1), "LEFT"),
            ("ALIGN", (1, 0), (1, -1), "RIGHT"),
            ("GRID", (0, 0), (-1, -1), 1, colors.lightgrey),
            ("TOPPADDING", (0, 0), (-1, -1), 8),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ]
    )


def _transactions_table_style() -> TableStyle:
    return TableStyle(
        [
            ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 9),
            ("FONT", (0, 1), (-1, -1), "Helvetica", 8),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0C1F3E")),
            ("ALIGN", (0, 0), (-1, -1), "RIGHT"),
            ("ALIGN", (0, 0), (1, -1), "LEFT"),
            ("GRID", (0, 0), (-1, -1), 1, colors.lightgrey),
            ("TOPPADDING", (0, 0), (-1, -1), 6),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9F9F9")]),
        ]
    )


def _breakdown_table_style() -> TableStyle:
    return TableStyle(
        [
            ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 11),
            ("FONT", (0, 1), (-1, -1), "Helvetica", 10),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0C1F3E")),
            ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E8E8E8")),
            ("FONT", (0, -1), (-1, -1), "Helvetica-Bold", 10),
            ("ALIGN", (0, 0), (-1, -1), "RIGHT"),
            ("ALIGN", (0, 0), (0, -1), "LEFT"),
            ("GRID", (0, 0), (-1, -1), 1, colors.black),
            ("TOPPADDING", (0, 0), (-1, -1), 8),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ]
    )
