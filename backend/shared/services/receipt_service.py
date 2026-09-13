from __future__ import annotations
from datetime import datetime
import os
import uuid

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy.orm import Session

from shared.models.db_models import Receipt


class ReceiptService:
    @staticmethod
    def generate_receipt_code(job_id: int, transaction_date: datetime | None = None) -> str:
        """Generate a receipt code in the format RCP-YYYYMMDD-JOBID-XXX."""
        transaction_date = transaction_date or datetime.utcnow()
        date_str = transaction_date.strftime("%Y%m%d")
        random_suffix = uuid.uuid4().hex[:3].upper()
        return f"RCP-{date_str}-{job_id:05d}-{random_suffix}"

    @staticmethod
    def create_receipt_pdf(
        job_id: int,
        job_title: str,
        tasker_name: str,
        recruiter_name: str,
        gross_amount: float,
        commission_percentage: float = 15,
        tax_percentage: float = 0,
        receipt_code: str | None = None,
        transaction_date: datetime | None = None,
    ) -> dict:
        """Generate a PDF receipt for a completed job."""
        try:
            transaction_date = transaction_date or datetime.utcnow()
            receipt_code = receipt_code or ReceiptService.generate_receipt_code(
                job_id, transaction_date
            )

            commission_amount = gross_amount * (commission_percentage / 100)
            tax_amount = gross_amount * (tax_percentage / 100)
            net_amount = gross_amount - commission_amount - tax_amount

            output_dir = os.getenv("TASKLY_RECEIPTS_DIR", "receipts")
            os.makedirs(output_dir, exist_ok=True)
            file_path = os.path.join(output_dir, f"receipt_{receipt_code}.pdf")

            doc = SimpleDocTemplate(file_path, pagesize=letter)
            styles = getSampleStyleSheet()
            story = []

            title_style = ParagraphStyle(
                "ReceiptTitle",
                parent=styles["Heading1"],
                fontSize=24,
                textColor=colors.HexColor("#0C1F3E"),
                spaceAfter=24,
                alignment=TA_CENTER,
                fontName="Helvetica-Bold",
            )
            heading_style = ParagraphStyle(
                "ReceiptHeading",
                parent=styles["Heading2"],
                fontSize=12,
                textColor=colors.HexColor("#0C1F3E"),
                spaceAfter=6,
                fontName="Helvetica-Bold",
            )
            footer_style = ParagraphStyle(
                "ReceiptFooter",
                parent=styles["Normal"],
                fontSize=8,
                textColor=colors.grey,
                alignment=TA_CENTER,
            )

            story.append(Paragraph("TASKLY RECEIPT", title_style))
            story.append(Spacer(1, 0.2 * inch))

            info_table = Table(
                [
                    ["Receipt Code:", receipt_code],
                    ["Date:", transaction_date.strftime("%B %d, %Y at %H:%M UTC")],
                    ["Job ID:", f"JOB-{job_id:05d}"],
                ],
                colWidths=[2 * inch, 4 * inch],
            )
            info_table.setStyle(_label_value_table_style())
            story.append(info_table)
            story.append(Spacer(1, 0.3 * inch))

            story.append(Paragraph("TRANSACTION DETAILS", heading_style))
            parties_table = Table(
                [
                    ["Recruiter:", recruiter_name],
                    ["Service Provider:", tasker_name],
                    ["Service:", job_title],
                ],
                colWidths=[1.7 * inch, 4.3 * inch],
            )
            parties_table.setStyle(_label_value_table_style())
            story.append(parties_table)
            story.append(Spacer(1, 0.3 * inch))

            story.append(Paragraph("FINANCIAL SUMMARY", heading_style))
            summary_table = Table(
                [
                    ["Description", "Amount (KES)"],
                    ["Gross Service Fee", f"{gross_amount:,.2f}"],
                    [f"Platform Commission ({commission_percentage:g}%)", f"-{commission_amount:,.2f}"],
                    [f"Applicable Tax ({tax_percentage:g}%)", f"-{tax_amount:,.2f}"],
                    ["Net Payment", f"{net_amount:,.2f}"],
                ],
                colWidths=[3.5 * inch, 2.5 * inch],
            )
            summary_table.setStyle(
                TableStyle(
                    [
                        ("FONT", (0, 0), (-1, -1), "Helvetica", 10),
                        ("FONT", (0, 0), (-1, 0), "Helvetica-Bold", 11),
                        ("FONT", (-1, -1), (-1, -1), "Helvetica-Bold", 11),
                        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0C1F3E")),
                        ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E8E8E8")),
                        ("ALIGN", (0, 0), (-1, -1), "RIGHT"),
                        ("ALIGN", (0, 0), (0, -1), "LEFT"),
                        ("TOPPADDING", (0, 0), (-1, -1), 8),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                        ("GRID", (0, 0), (-1, -1), 1, colors.black),
                    ]
                )
            )
            story.append(summary_table)
            story.append(Spacer(1, 0.4 * inch))
            story.append(
                Paragraph(
                    "This is an automatically generated receipt. For support, contact support@taskly.com",
                    footer_style,
                )
            )
            story.append(
                Paragraph(
                    f"Taskly 2026 | Receipt Generated: {datetime.utcnow():%Y-%m-%d %H:%M:%S UTC}",
                    footer_style,
                )
            )

            doc.build(story)

            return {
                "success": True,
                "file_path": file_path,
                "receipt_code": receipt_code,
                "gross_amount": gross_amount,
                "commission_amount": commission_amount,
                "tax_amount": tax_amount,
                "net_amount": net_amount,
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    @staticmethod
    def save_receipt_to_db(
        db: Session,
        job_id: int,
        user_id: int,
        gross_amount: float,
        receipt_code: str,
        pdf_path: str,
        commission_percentage: float = 15,
        tax_percentage: float = 0,
        status: str = "paid",
    ) -> dict:
        """Save a receipt record, returning the existing record for duplicate codes."""
        try:
            existing = db.query(Receipt).filter(Receipt.receipt_code == receipt_code).first()
            if existing:
                return {
                    "success": True,
                    "receipt_id": existing.id,
                    "receipt_code": existing.receipt_code,
                    "duplicate": True,
                }

            commission_amount = gross_amount * (commission_percentage / 100)
            tax_amount = gross_amount * (tax_percentage / 100)
            net_amount = gross_amount - commission_amount - tax_amount

            receipt = Receipt(
                receipt_code=receipt_code,
                job_id=job_id,
                user_id=user_id,
                amount=gross_amount,
                commission_amount=commission_amount,
                net_amount=net_amount,
                tax_amount=tax_amount,
                status=status,
                pdf_url=pdf_path,
                paid_at=datetime.utcnow() if status == "paid" else None,
            )

            db.add(receipt)
            db.flush()

            return {
                "success": True,
                "receipt_id": receipt.id,
                "receipt_code": receipt.receipt_code,
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}

    @staticmethod
    def get_receipt(db: Session, receipt_code: str) -> dict:
        """Retrieve receipt details."""
        try:
            receipt = db.query(Receipt).filter(Receipt.receipt_code == receipt_code).first()
            if not receipt:
                return {"success": False, "error": "Receipt not found"}

            return {
                "success": True,
                "receipt_code": receipt.receipt_code,
                "job_id": receipt.job_id,
                "user_id": receipt.user_id,
                "amount": receipt.amount,
                "commission": receipt.commission_amount,
                "tax": receipt.tax_amount,
                "net_amount": receipt.net_amount,
                "status": receipt.status,
                "pdf_url": receipt.pdf_url,
                "created_at": receipt.created_at.isoformat() if receipt.created_at else None,
                "paid_at": receipt.paid_at.isoformat() if receipt.paid_at else None,
            }
        except Exception as exc:
            return {"success": False, "error": str(exc)}


def _label_value_table_style() -> TableStyle:
    return TableStyle(
        [
            ("FONT", (0, 0), (-1, -1), "Helvetica", 10),
            ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 10),
            ("TEXTCOLOR", (0, 0), (0, -1), colors.HexColor("#0C1F3E")),
            ("ALIGN", (0, 0), (-1, -1), "LEFT"),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ]
    )
