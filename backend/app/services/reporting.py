"""
Reporting and Analytics Service
"""

from sqlalchemy.orm import Session
from sqlalchemy import func, extract, and_, or_
from typing import Dict, List, Optional, Any
from datetime import datetime, date, timedelta
from decimal import Decimal
import calendar
from collections import defaultdict

from app.models.transaction import Transaction
from app.models.category import Category
from app.models.user import User


class ReportingService:
    """Service for generating financial reports and analytics"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_monthly_summary(self, user_id: int, year: int, month: int) -> Dict[str, Any]:
        """Get monthly financial summary for a user"""
        
        # Get start and end dates for the month
        start_date = date(year, month, 1)
        if month == 12:
            end_date = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            end_date = date(year, month + 1, 1) - timedelta(days=1)
        
        # Query transactions for the month
        transactions = self.db.query(
            Transaction,
            Category.type.label('category_type'),
            Category.name.label('category_name'),
            Category.icon.label('category_icon'),
            Category.color.label('category_color')
        ).join(
            Category, Transaction.category_id == Category.id
        ).filter(
            and_(
                Transaction.user_id == user_id,
                Transaction.trans_date >= start_date,
                Transaction.trans_date <= end_date
            )
        ).all()
        
        # Calculate totals
        total_income = Decimal('0')
        total_expense = Decimal('0')
        category_breakdown = defaultdict(lambda: {
            'income': Decimal('0'),
            'expense': Decimal('0'),
            'count': 0,
            'icon': '',
            'color': ''
        })
        
        daily_summary = defaultdict(lambda: {
            'income': Decimal('0'),
            'expense': Decimal('0'),
            'balance': Decimal('0')
        })
        
        for transaction, category_type, category_name, category_icon, category_color in transactions:
            amount = transaction.amount
            transaction_date = transaction.trans_date.strftime('%Y-%m-%d')
            
            if category_type == 'income':
                total_income += amount
                category_breakdown[category_name]['income'] += amount
                daily_summary[transaction_date]['income'] += amount
            else:
                total_expense += amount
                category_breakdown[category_name]['expense'] += amount
                daily_summary[transaction_date]['expense'] += amount
            
            category_breakdown[category_name]['count'] += 1
            category_breakdown[category_name]['icon'] = category_icon or ''
            category_breakdown[category_name]['color'] = category_color or ''
        
        # Calculate daily balances
        for day_data in daily_summary.values():
            day_data['balance'] = day_data['income'] - day_data['expense']
        
        # Convert category breakdown to list format
        category_list = []
        for category_name, data in category_breakdown.items():
            category_list.append({
                'category_name': category_name,
                'income': float(data['income']),
                'expense': float(data['expense']),
                'total': float(data['income'] + data['expense']),
                'count': data['count'],
                'icon': data['icon'],
                'color': data['color']
            })
        
        # Sort categories by total amount (descending)
        category_list.sort(key=lambda x: x['total'], reverse=True)
        
        # Convert daily summary to list format
        daily_list = []
        for day, data in daily_summary.items():
            daily_list.append({
                'date': day,
                'income': float(data['income']),
                'expense': float(data['expense']),
                'balance': float(data['balance'])
            })
        
        # Sort daily summary by date
        daily_list.sort(key=lambda x: x['date'])
        
        balance = total_income - total_expense
        
        return {
            'period': {
                'year': year,
                'month': month,
                'month_name': calendar.month_name[month],
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat(),
                'days_in_month': (end_date - start_date).days + 1
            },
            'summary': {
                'total_income': float(total_income),
                'total_expense': float(total_expense),
                'balance': float(balance),
                'transaction_count': len(transactions),
                'avg_daily_expense': float(total_expense / (end_date - start_date).days) if (end_date - start_date).days > 0 else 0,
                'avg_daily_income': float(total_income / (end_date - start_date).days) if (end_date - start_date).days > 0 else 0
            },
            'category_breakdown': category_list,
            'daily_summary': daily_list
        }
    
    def get_yearly_comparison(self, user_id: int, year: int) -> Dict[str, Any]:
        """Get yearly financial comparison by month"""
        
        monthly_data = []
        
        for month in range(1, 13):
            month_summary = self.get_monthly_summary(user_id, year, month)
            monthly_data.append({
                'month': month,
                'month_name': calendar.month_name[month],
                'income': month_summary['summary']['total_income'],
                'expense': month_summary['summary']['total_expense'],
                'balance': month_summary['summary']['balance'],
                'transaction_count': month_summary['summary']['transaction_count']
            })
        
        # Calculate yearly totals
        yearly_income = sum(month['income'] for month in monthly_data)
        yearly_expense = sum(month['expense'] for month in monthly_data)
        yearly_balance = yearly_income - yearly_expense
        
        # Find best and worst months
        best_month = max(monthly_data, key=lambda x: x['balance'])
        worst_month = min(monthly_data, key=lambda x: x['balance'])
        highest_income_month = max(monthly_data, key=lambda x: x['income'])
        highest_expense_month = max(monthly_data, key=lambda x: x['expense'])
        
        return {
            'year': year,
            'summary': {
                'yearly_income': yearly_income,
                'yearly_expense': yearly_expense,
                'yearly_balance': yearly_balance,
                'avg_monthly_income': yearly_income / 12,
                'avg_monthly_expense': yearly_expense / 12,
                'total_transactions': sum(month['transaction_count'] for month in monthly_data)
            },
            'monthly_data': monthly_data,
            'insights': {
                'best_month': {
                    'month': best_month['month_name'],
                    'balance': best_month['balance']
                },
                'worst_month': {
                    'month': worst_month['month_name'],
                    'balance': worst_month['balance']
                },
                'highest_income_month': {
                    'month': highest_income_month['month_name'],
                    'income': highest_income_month['income']
                },
                'highest_expense_month': {
                    'month': highest_expense_month['month_name'],
                    'expense': highest_expense_month['expense']
                }
            }
        }
    
    def get_category_analysis(self, user_id: int, start_date: date, end_date: date) -> Dict[str, Any]:
        """Get detailed category analysis for a date range"""
        
        # Query transactions with category info
        results = self.db.query(
            Category.name,
            Category.type,
            Category.icon,
            Category.color,
            func.sum(Transaction.amount).label('total_amount'),
            func.count(Transaction.id).label('transaction_count'),
            func.avg(Transaction.amount).label('avg_amount'),
            func.max(Transaction.amount).label('max_amount'),
            func.min(Transaction.amount).label('min_amount')
        ).join(
            Transaction, Category.id == Transaction.category_id
        ).filter(
            and_(
                Transaction.user_id == user_id,
                Transaction.trans_date >= start_date,
                Transaction.trans_date <= end_date
            )
        ).group_by(
            Category.id, Category.name, Category.type, Category.icon, Category.color
        ).all()
        
        income_categories = []
        expense_categories = []
        total_income = Decimal('0')
        total_expense = Decimal('0')
        
        for result in results:
            category_data = {
                'name': result.name,
                'type': result.type,
                'icon': result.icon,
                'color': result.color,
                'total_amount': float(result.total_amount or 0),
                'transaction_count': result.transaction_count,
                'avg_amount': float(result.avg_amount or 0),
                'max_amount': float(result.max_amount or 0),
                'min_amount': float(result.min_amount or 0)
            }
            
            if result.type == 'income':
                income_categories.append(category_data)
                total_income += (result.total_amount or 0)
            else:
                expense_categories.append(category_data)
                total_expense += (result.total_amount or 0)
        
        # Calculate percentages
        for category in income_categories:
            category['percentage'] = (category['total_amount'] / float(total_income) * 100) if total_income > 0 else 0
        
        for category in expense_categories:
            category['percentage'] = (category['total_amount'] / float(total_expense) * 100) if total_expense > 0 else 0
        
        # Sort by total amount
        income_categories.sort(key=lambda x: x['total_amount'], reverse=True)
        expense_categories.sort(key=lambda x: x['total_amount'], reverse=True)
        
        return {
            'period': {
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat(),
                'days': (end_date - start_date).days + 1
            },
            'summary': {
                'total_income': float(total_income),
                'total_expense': float(total_expense),
                'balance': float(total_income - total_expense),
                'income_categories_count': len(income_categories),
                'expense_categories_count': len(expense_categories)
            },
            'income_categories': income_categories,
            'expense_categories': expense_categories
        }
    
    def get_spending_trends(self, user_id: int, months: int = 6) -> Dict[str, Any]:
        """Get spending trends for the last N months"""
        
        end_date = date.today()
        start_date = end_date.replace(day=1) - timedelta(days=months * 30)  # Approximate
        
        # Get monthly spending for each category
        results = self.db.query(
            extract('year', Transaction.trans_date).label('year'),
            extract('month', Transaction.trans_date).label('month'),
            Category.name.label('category_name'),
            Category.type.label('category_type'),
            func.sum(Transaction.amount).label('total_amount')
        ).join(
            Category, Transaction.category_id == Category.id
        ).filter(
            and_(
                Transaction.user_id == user_id,
                Transaction.trans_date >= start_date,
                Transaction.trans_date <= end_date
            )
        ).group_by(
            extract('year', Transaction.trans_date),
            extract('month', Transaction.trans_date),
            Category.name,
            Category.type
        ).order_by(
            extract('year', Transaction.trans_date),
            extract('month', Transaction.trans_date)
        ).all()
        
        # Organize data by month and category
        trends = defaultdict(lambda: defaultdict(lambda: {'income': 0, 'expense': 0}))
        
        for result in results:
            month_key = f"{int(result.year)}-{int(result.month):02d}"
            category = result.category_name
            amount = float(result.total_amount or 0)
            
            if result.category_type == 'income':
                trends[month_key][category]['income'] = amount
            else:
                trends[month_key][category]['expense'] = amount
        
        # Convert to list format
        trend_data = []
        for month_key in sorted(trends.keys()):
            month_data = {
                'month': month_key,
                'categories': []
            }
            
            for category, amounts in trends[month_key].items():
                month_data['categories'].append({
                    'category': category,
                    'income': amounts['income'],
                    'expense': amounts['expense'],
                    'net': amounts['income'] - amounts['expense']
                })
            
            trend_data.append(month_data)
        
        return {
            'period': {
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat(),
                'months': months
            },
            'trends': trend_data
        }
    
    def get_financial_insights(self, user_id: int) -> Dict[str, Any]:
        """Get financial insights and recommendations"""
        
        # Get current month data
        now = datetime.now()
        current_month = self.get_monthly_summary(user_id, now.year, now.month)
        
        # Get previous month data for comparison
        prev_month = now.month - 1 if now.month > 1 else 12
        prev_year = now.year if now.month > 1 else now.year - 1
        previous_month = self.get_monthly_summary(user_id, prev_year, prev_month)
        
        # Calculate changes
        income_change = current_month['summary']['total_income'] - previous_month['summary']['total_income']
        expense_change = current_month['summary']['total_expense'] - previous_month['summary']['total_expense']
        
        income_change_pct = (income_change / previous_month['summary']['total_income'] * 100) if previous_month['summary']['total_income'] > 0 else 0
        expense_change_pct = (expense_change / previous_month['summary']['total_expense'] * 100) if previous_month['summary']['total_expense'] > 0 else 0
        
        # Generate insights
        insights = []
        
        if income_change > 0:
            insights.append({
                'type': 'positive',
                'category': 'income',
                'message': f"Your income increased by {income_change_pct:.1f}% compared to last month",
                'value': income_change
            })
        elif income_change < 0:
            insights.append({
                'type': 'warning',
                'category': 'income',
                'message': f"Your income decreased by {abs(income_change_pct):.1f}% compared to last month",
                'value': income_change
            })
        
        if expense_change > 0:
            insights.append({
                'type': 'warning',
                'category': 'expense',
                'message': f"Your expenses increased by {expense_change_pct:.1f}% compared to last month",
                'value': expense_change
            })
        elif expense_change < 0:
            insights.append({
                'type': 'positive',
                'category': 'expense',
                'message': f"You reduced expenses by {abs(expense_change_pct):.1f}% compared to last month",
                'value': expense_change
            })
        
        # Find top spending categories
        top_expense_categories = [cat for cat in current_month['category_breakdown'] if cat['expense'] > 0][:3]
        
        if top_expense_categories:
            insights.append({
                'type': 'info',
                'category': 'spending',
                'message': f"Your top spending category this month is '{top_expense_categories[0]['category_name']}'",
                'value': top_expense_categories[0]['expense']
            })
        
        # Savings rate insight
        savings_rate = (current_month['summary']['balance'] / current_month['summary']['total_income'] * 100) if current_month['summary']['total_income'] > 0 else 0
        
        if savings_rate > 20:
            insights.append({
                'type': 'positive',
                'category': 'savings',
                'message': f"Excellent! You're saving {savings_rate:.1f}% of your income",
                'value': savings_rate
            })
        elif savings_rate > 10:
            insights.append({
                'type': 'info',
                'category': 'savings',
                'message': f"Good job! You're saving {savings_rate:.1f}% of your income",
                'value': savings_rate
            })
        elif savings_rate > 0:
            insights.append({
                'type': 'warning',
                'category': 'savings',
                'message': f"Consider increasing your savings rate. Currently at {savings_rate:.1f}%",
                'value': savings_rate
            })
        else:
            insights.append({
                'type': 'negative',
                'category': 'savings',
                'message': "You're spending more than you earn this month",
                'value': savings_rate
            })
        
        return {
            'current_month': current_month['summary'],
            'previous_month': previous_month['summary'],
            'changes': {
                'income_change': income_change,
                'expense_change': expense_change,
                'income_change_pct': income_change_pct,
                'expense_change_pct': expense_change_pct
            },
            'insights': insights,
            'top_categories': top_expense_categories,
            'savings_rate': savings_rate
        }
