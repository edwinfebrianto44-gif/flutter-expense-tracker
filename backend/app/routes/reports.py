"""
Reporting and Analytics API endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import Optional, Literal
from datetime import datetime, date
import calendar
import io

from app.core.deps import get_db, get_current_user
from app.core.response import success_response, error_response
from app.models.user import User
from app.services.reporting import ReportingService
from app.services.export import report_export_service

router = APIRouter()


@router.get("/summary")
async def get_monthly_summary(
    month: str = Query(..., description="Month in YYYY-MM format", regex=r"^\d{4}-\d{2}$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get monthly financial summary
    
    - **month**: Month in YYYY-MM format (e.g., 2024-03)
    - **Returns**: Monthly financial summary with category breakdown and daily data
    """
    
    try:
        # Parse month parameter
        year, month_num = map(int, month.split('-'))
        
        # Validate month
        if month_num < 1 or month_num > 12:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response("Invalid month. Must be between 01 and 12")
            )
        
        # Create reporting service
        reporting_service = ReportingService(db)
        
        # Get monthly summary
        summary_data = reporting_service.get_monthly_summary(
            current_user.id, year, month_num
        )
        
        return success_response(
            message="Monthly summary retrieved successfully",
            data=summary_data
        )
        
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_response("Invalid month format. Use YYYY-MM")
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to generate monthly summary: {str(e)}")
        )


@router.get("/yearly")
async def get_yearly_comparison(
    year: int = Query(..., description="Year for comparison"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get yearly financial comparison by month
    
    - **year**: Year for comparison (e.g., 2024)
    - **Returns**: Yearly comparison with monthly breakdown and insights
    """
    
    try:
        # Validate year
        current_year = datetime.now().year
        if year < 2000 or year > current_year + 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response(f"Invalid year. Must be between 2000 and {current_year + 1}")
            )
        
        # Create reporting service
        reporting_service = ReportingService(db)
        
        # Get yearly comparison
        yearly_data = reporting_service.get_yearly_comparison(current_user.id, year)
        
        return success_response(
            message="Yearly comparison retrieved successfully",
            data=yearly_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to generate yearly comparison: {str(e)}")
        )


@router.get("/categories")
async def get_category_analysis(
    start_date: date = Query(..., description="Start date for analysis"),
    end_date: date = Query(..., description="End date for analysis"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get detailed category analysis for a date range
    
    - **start_date**: Start date for analysis (YYYY-MM-DD)
    - **end_date**: End date for analysis (YYYY-MM-DD)
    - **Returns**: Category analysis with percentages and statistics
    """
    
    try:
        # Validate date range
        if start_date > end_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response("Start date must be before end date")
            )
        
        # Check if date range is not too large (max 2 years)
        if (end_date - start_date).days > 730:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response("Date range too large. Maximum 2 years allowed")
            )
        
        # Create reporting service
        reporting_service = ReportingService(db)
        
        # Get category analysis
        analysis_data = reporting_service.get_category_analysis(
            current_user.id, start_date, end_date
        )
        
        return success_response(
            message="Category analysis retrieved successfully",
            data=analysis_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to generate category analysis: {str(e)}")
        )


@router.get("/trends")
async def get_spending_trends(
    months: int = Query(6, description="Number of months to analyze", ge=1, le=24),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get spending trends for the last N months
    
    - **months**: Number of months to analyze (1-24, default: 6)
    - **Returns**: Spending trends by category over time
    """
    
    try:
        # Create reporting service
        reporting_service = ReportingService(db)
        
        # Get spending trends
        trends_data = reporting_service.get_spending_trends(current_user.id, months)
        
        return success_response(
            message="Spending trends retrieved successfully",
            data=trends_data
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to generate spending trends: {str(e)}")
        )


@router.get("/insights")
async def get_financial_insights(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get financial insights and recommendations
    
    - **Returns**: Financial insights, trends, and personalized recommendations
    """
    
    try:
        # Create reporting service
        reporting_service = ReportingService(db)
        
        # Get financial insights
        insights_data = reporting_service.get_financial_insights(current_user.id)
        
        return success_response(
            message="Financial insights retrieved successfully",
            data=insights_data
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to generate financial insights: {str(e)}")
        )


@router.get("/export/monthly")
async def export_monthly_report(
    month: str = Query(..., description="Month in YYYY-MM format", regex=r"^\d{4}-\d{2}$"),
    format: Literal["csv", "pdf"] = Query("csv", description="Export format"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Export monthly report in CSV or PDF format
    
    - **month**: Month in YYYY-MM format (e.g., 2024-03)
    - **format**: Export format (csv or pdf)
    - **Returns**: Downloadable file
    """
    
    try:
        # Parse month parameter
        year, month_num = map(int, month.split('-'))
        
        # Validate month
        if month_num < 1 or month_num > 12:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response("Invalid month. Must be between 01 and 12")
            )
        
        # Get report data
        reporting_service = ReportingService(db)
        report_data = reporting_service.get_monthly_summary(
            current_user.id, year, month_num
        )
        
        # Generate filename
        month_name = calendar.month_name[month_num]
        filename = f"monthly_report_{year}_{month_num:02d}_{month_name.lower()}"
        
        if format == "csv":
            # Export to CSV
            csv_output = report_export_service.export_monthly_summary_csv(report_data)
            
            return StreamingResponse(
                io.StringIO(csv_output.getvalue()),
                media_type="text/csv",
                headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
            )
        
        elif format == "pdf":
            # Export to PDF
            pdf_output = report_export_service.export_monthly_summary_pdf(report_data)
            
            return StreamingResponse(
                io.BytesIO(pdf_output.getvalue()),
                media_type="application/pdf",
                headers={"Content-Disposition": f"attachment; filename={filename}.pdf"}
            )
        
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_response("Invalid month format. Use YYYY-MM")
        )
    except ImportError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Export functionality not available: {str(e)}")
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to export monthly report: {str(e)}")
        )


@router.get("/export/yearly")
async def export_yearly_report(
    year: int = Query(..., description="Year for export"),
    format: Literal["csv", "pdf"] = Query("csv", description="Export format"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Export yearly report in CSV or PDF format
    
    - **year**: Year for export (e.g., 2024)
    - **format**: Export format (csv or pdf)
    - **Returns**: Downloadable file
    """
    
    try:
        # Validate year
        current_year = datetime.now().year
        if year < 2000 or year > current_year + 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response(f"Invalid year. Must be between 2000 and {current_year + 1}")
            )
        
        # Get report data
        reporting_service = ReportingService(db)
        report_data = reporting_service.get_yearly_comparison(current_user.id, year)
        
        # Generate filename
        filename = f"yearly_report_{year}"
        
        if format == "csv":
            # Export to CSV
            csv_output = report_export_service.export_yearly_comparison_csv(report_data)
            
            return StreamingResponse(
                io.StringIO(csv_output.getvalue()),
                media_type="text/csv",
                headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
            )
        
        elif format == "pdf":
            # Export to PDF
            pdf_output = report_export_service.export_yearly_comparison_pdf(report_data)
            
            return StreamingResponse(
                io.BytesIO(pdf_output.getvalue()),
                media_type="application/pdf",
                headers={"Content-Disposition": f"attachment; filename={filename}.pdf"}
            )
        
    except ImportError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Export functionality not available: {str(e)}")
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to export yearly report: {str(e)}")
        )


@router.get("/export/categories")
async def export_category_analysis(
    start_date: date = Query(..., description="Start date for analysis"),
    end_date: date = Query(..., description="End date for analysis"),
    format: Literal["csv", "pdf"] = Query("csv", description="Export format"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Export category analysis in CSV or PDF format
    
    - **start_date**: Start date for analysis (YYYY-MM-DD)
    - **end_date**: End date for analysis (YYYY-MM-DD)
    - **format**: Export format (csv or pdf)
    - **Returns**: Downloadable file
    """
    
    try:
        # Validate date range
        if start_date > end_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response("Start date must be before end date")
            )
        
        # Check if date range is not too large (max 2 years)
        if (end_date - start_date).days > 730:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error_response("Date range too large. Maximum 2 years allowed")
            )
        
        # Get report data
        reporting_service = ReportingService(db)
        report_data = reporting_service.get_category_analysis(
            current_user.id, start_date, end_date
        )
        
        # Generate filename
        filename = f"category_analysis_{start_date}_{end_date}"
        
        if format == "csv":
            # Export to CSV
            csv_output = report_export_service.export_category_analysis_csv(report_data)
            
            return StreamingResponse(
                io.StringIO(csv_output.getvalue()),
                media_type="text/csv",
                headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
            )
        
        elif format == "pdf":
            # For PDF, we can reuse the monthly PDF format or create a specific one
            # For now, return CSV as PDF generation for category analysis is complex
            raise HTTPException(
                status_code=status.HTTP_501_NOT_IMPLEMENTED,
                detail=error_response("PDF export for category analysis not yet implemented")
            )
        
    except ImportError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Export functionality not available: {str(e)}")
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Failed to export category analysis: {str(e)}")
        )
