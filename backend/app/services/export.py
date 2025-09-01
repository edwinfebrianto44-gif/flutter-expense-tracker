"""
Report Export Service for PDF and CSV generation
"""

import csv
import io
from typing import Dict, List, Any, Optional
from datetime import datetime, date
import calendar
from decimal import Decimal

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.graphics.shapes import Drawing
    from reportlab.graphics.charts.piecharts import Pie
    from reportlab.graphics.charts.barcharts import VerticalBarChart
    from reportlab.lib.colors import HexColor
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False


class ReportExportService:
    """Service for exporting reports to PDF and CSV formats"""
    
    def __init__(self):
        self.styles = getSampleStyleSheet() if REPORTLAB_AVAILABLE else None
    
    def export_monthly_summary_csv(self, report_data: Dict[str, Any]) -> io.StringIO:
        """Export monthly summary to CSV format"""
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header information
        period = report_data['period']
        summary = report_data['summary']
        
        writer.writerow(['Monthly Financial Report'])
        writer.writerow(['Period', f"{period['month_name']} {period['year']}"])
        writer.writerow(['Start Date', period['start_date']])
        writer.writerow(['End Date', period['end_date']])
        writer.writerow([])
        
        # Write summary
        writer.writerow(['Summary'])
        writer.writerow(['Total Income', f"${summary['total_income']:.2f}"])
        writer.writerow(['Total Expense', f"${summary['total_expense']:.2f}"])
        writer.writerow(['Balance', f"${summary['balance']:.2f}"])
        writer.writerow(['Transaction Count', summary['transaction_count']])
        writer.writerow(['Avg Daily Income', f"${summary['avg_daily_income']:.2f}"])
        writer.writerow(['Avg Daily Expense', f"${summary['avg_daily_expense']:.2f}"])
        writer.writerow([])
        
        # Write category breakdown
        writer.writerow(['Category Breakdown'])
        writer.writerow(['Category', 'Income', 'Expense', 'Total', 'Transaction Count', 'Percentage'])
        
        total_amount = summary['total_income'] + summary['total_expense']
        for category in report_data['category_breakdown']:
            percentage = (category['total'] / total_amount * 100) if total_amount > 0 else 0
            writer.writerow([
                category['category_name'],
                f"${category['income']:.2f}",
                f"${category['expense']:.2f}",
                f"${category['total']:.2f}",
                category['count'],
                f"{percentage:.1f}%"
            ])
        
        writer.writerow([])
        
        # Write daily summary
        writer.writerow(['Daily Summary'])
        writer.writerow(['Date', 'Income', 'Expense', 'Balance'])
        
        for day in report_data['daily_summary']:
            writer.writerow([
                day['date'],
                f"${day['income']:.2f}",
                f"${day['expense']:.2f}",
                f"${day['balance']:.2f}"
            ])
        
        output.seek(0)
        return output
    
    def export_yearly_comparison_csv(self, report_data: Dict[str, Any]) -> io.StringIO:
        """Export yearly comparison to CSV format"""
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header information
        summary = report_data['summary']
        
        writer.writerow(['Yearly Financial Report'])
        writer.writerow(['Year', report_data['year']])
        writer.writerow([])
        
        # Write summary
        writer.writerow(['Annual Summary'])
        writer.writerow(['Yearly Income', f"${summary['yearly_income']:.2f}"])
        writer.writerow(['Yearly Expense', f"${summary['yearly_expense']:.2f}"])
        writer.writerow(['Yearly Balance', f"${summary['yearly_balance']:.2f}"])
        writer.writerow(['Avg Monthly Income', f"${summary['avg_monthly_income']:.2f}"])
        writer.writerow(['Avg Monthly Expense', f"${summary['avg_monthly_expense']:.2f}"])
        writer.writerow(['Total Transactions', summary['total_transactions']])
        writer.writerow([])
        
        # Write monthly data
        writer.writerow(['Monthly Breakdown'])
        writer.writerow(['Month', 'Income', 'Expense', 'Balance', 'Transaction Count'])
        
        for month_data in report_data['monthly_data']:
            writer.writerow([
                month_data['month_name'],
                f"${month_data['income']:.2f}",
                f"${month_data['expense']:.2f}",
                f"${month_data['balance']:.2f}",
                month_data['transaction_count']
            ])
        
        writer.writerow([])
        
        # Write insights
        insights = report_data['insights']
        writer.writerow(['Key Insights'])
        writer.writerow(['Best Month (Balance)', insights['best_month']['month'], f"${insights['best_month']['balance']:.2f}"])
        writer.writerow(['Worst Month (Balance)', insights['worst_month']['month'], f"${insights['worst_month']['balance']:.2f}"])
        writer.writerow(['Highest Income Month', insights['highest_income_month']['month'], f"${insights['highest_income_month']['income']:.2f}"])
        writer.writerow(['Highest Expense Month', insights['highest_expense_month']['month'], f"${insights['highest_expense_month']['expense']:.2f}"])
        
        output.seek(0)
        return output
    
    def export_category_analysis_csv(self, report_data: Dict[str, Any]) -> io.StringIO:
        """Export category analysis to CSV format"""
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header information
        period = report_data['period']
        summary = report_data['summary']
        
        writer.writerow(['Category Analysis Report'])
        writer.writerow(['Period', f"{period['start_date']} to {period['end_date']}"])
        writer.writerow(['Days', period['days']])
        writer.writerow([])
        
        # Write summary
        writer.writerow(['Summary'])
        writer.writerow(['Total Income', f"${summary['total_income']:.2f}"])
        writer.writerow(['Total Expense', f"${summary['total_expense']:.2f}"])
        writer.writerow(['Balance', f"${summary['balance']:.2f}"])
        writer.writerow(['Income Categories', summary['income_categories_count']])
        writer.writerow(['Expense Categories', summary['expense_categories_count']])
        writer.writerow([])
        
        # Write income categories
        writer.writerow(['Income Categories'])
        writer.writerow(['Category', 'Total Amount', 'Percentage', 'Transaction Count', 'Avg Amount', 'Max Amount', 'Min Amount'])
        
        for category in report_data['income_categories']:
            writer.writerow([
                category['name'],
                f"${category['total_amount']:.2f}",
                f"{category['percentage']:.1f}%",
                category['transaction_count'],
                f"${category['avg_amount']:.2f}",
                f"${category['max_amount']:.2f}",
                f"${category['min_amount']:.2f}"
            ])
        
        writer.writerow([])
        
        # Write expense categories
        writer.writerow(['Expense Categories'])
        writer.writerow(['Category', 'Total Amount', 'Percentage', 'Transaction Count', 'Avg Amount', 'Max Amount', 'Min Amount'])
        
        for category in report_data['expense_categories']:
            writer.writerow([
                category['name'],
                f"${category['total_amount']:.2f}",
                f"{category['percentage']:.1f}%",
                category['transaction_count'],
                f"${category['avg_amount']:.2f}",
                f"${category['max_amount']:.2f}",
                f"${category['min_amount']:.2f}"
            ])
        
        output.seek(0)
        return output
    
    def export_monthly_summary_pdf(self, report_data: Dict[str, Any]) -> io.BytesIO:
        """Export monthly summary to PDF format"""
        
        if not REPORTLAB_AVAILABLE:
            raise ImportError("ReportLab is required for PDF export. Install with: pip install reportlab")
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        story = []
        
        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#2E7D32'),
            spaceAfter=30,
            alignment=1  # Center
        )
        
        period = report_data['period']
        summary = report_data['summary']
        
        story.append(Paragraph(f"Monthly Financial Report", title_style))
        story.append(Paragraph(f"{period['month_name']} {period['year']}", self.styles['Heading2']))
        story.append(Spacer(1, 20))
        
        # Summary table
        summary_data = [
            ['Metric', 'Amount'],
            ['Total Income', f"${summary['total_income']:.2f}"],
            ['Total Expense', f"${summary['total_expense']:.2f}"],
            ['Balance', f"${summary['balance']:.2f}"],
            ['Transaction Count', str(summary['transaction_count'])],
            ['Avg Daily Income', f"${summary['avg_daily_income']:.2f}"],
            ['Avg Daily Expense', f"${summary['avg_daily_expense']:.2f}"]
        ]
        
        summary_table = Table(summary_data, colWidths=[3*inch, 2*inch])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E8F5E8')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#2E7D32')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(Paragraph("Financial Summary", self.styles['Heading3']))
        story.append(summary_table)
        story.append(Spacer(1, 30))
        
        # Category breakdown
        if report_data['category_breakdown']:
            story.append(Paragraph("Category Breakdown", self.styles['Heading3']))
            
            category_data = [['Category', 'Income', 'Expense', 'Total', 'Count']]
            for category in report_data['category_breakdown'][:10]:  # Top 10
                category_data.append([
                    category['category_name'],
                    f"${category['income']:.2f}",
                    f"${category['expense']:.2f}",
                    f"${category['total']:.2f}",
                    str(category['count'])
                ])
            
            category_table = Table(category_data, colWidths=[2*inch, 1.2*inch, 1.2*inch, 1.2*inch, 0.8*inch])
            category_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E3F2FD')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#1565C0')),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('FONTSIZE', (0, 1), (-1, -1), 9),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.white),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            
            story.append(category_table)
        
        # Generate PDF
        doc.build(story)
        buffer.seek(0)
        return buffer
    
    def export_yearly_comparison_pdf(self, report_data: Dict[str, Any]) -> io.BytesIO:
        """Export yearly comparison to PDF format"""
        
        if not REPORTLAB_AVAILABLE:
            raise ImportError("ReportLab is required for PDF export. Install with: pip install reportlab")
        
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        story = []
        
        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#2E7D32'),
            spaceAfter=30,
            alignment=1  # Center
        )
        
        summary = report_data['summary']
        
        story.append(Paragraph(f"Yearly Financial Report", title_style))
        story.append(Paragraph(f"Year {report_data['year']}", self.styles['Heading2']))
        story.append(Spacer(1, 20))
        
        # Annual summary table
        annual_data = [
            ['Metric', 'Amount'],
            ['Yearly Income', f"${summary['yearly_income']:.2f}"],
            ['Yearly Expense', f"${summary['yearly_expense']:.2f}"],
            ['Yearly Balance', f"${summary['yearly_balance']:.2f}"],
            ['Avg Monthly Income', f"${summary['avg_monthly_income']:.2f}"],
            ['Avg Monthly Expense', f"${summary['avg_monthly_expense']:.2f}"],
            ['Total Transactions', str(summary['total_transactions'])]
        ]
        
        annual_table = Table(annual_data, colWidths=[3*inch, 2*inch])
        annual_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E8F5E8')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#2E7D32')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(Paragraph("Annual Summary", self.styles['Heading3']))
        story.append(annual_table)
        story.append(Spacer(1, 30))
        
        # Monthly breakdown
        story.append(Paragraph("Monthly Breakdown", self.styles['Heading3']))
        
        monthly_data = [['Month', 'Income', 'Expense', 'Balance', 'Transactions']]
        for month in report_data['monthly_data']:
            monthly_data.append([
                month['month_name'],
                f"${month['income']:.2f}",
                f"${month['expense']:.2f}",
                f"${month['balance']:.2f}",
                str(month['transaction_count'])
            ])
        
        monthly_table = Table(monthly_data, colWidths=[1.5*inch, 1.2*inch, 1.2*inch, 1.2*inch, 1*inch])
        monthly_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E3F2FD')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#1565C0')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(monthly_table)
        story.append(Spacer(1, 20))
        
        # Insights
        insights = report_data['insights']
        story.append(Paragraph("Key Insights", self.styles['Heading3']))
        
        insights_data = [
            ['Insight', 'Details'],
            ['Best Month (Balance)', f"{insights['best_month']['month']}: ${insights['best_month']['balance']:.2f}"],
            ['Worst Month (Balance)', f"{insights['worst_month']['month']}: ${insights['worst_month']['balance']:.2f}"],
            ['Highest Income Month', f"{insights['highest_income_month']['month']}: ${insights['highest_income_month']['income']:.2f}"],
            ['Highest Expense Month', f"{insights['highest_expense_month']['month']}: ${insights['highest_expense_month']['expense']:.2f}"]
        ]
        
        insights_table = Table(insights_data, colWidths=[2.5*inch, 3*inch])
        insights_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FFF3E0')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.HexColor('#F57C00')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(insights_table)
        
        # Generate PDF
        doc.build(story)
        buffer.seek(0)
        return buffer


# Global export service instance
report_export_service = ReportExportService()
