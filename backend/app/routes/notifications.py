from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
import firebase_admin
from firebase_admin import credentials, messaging
from pydantic import BaseModel
from datetime import datetime, timedelta
import os

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.user import UserResponse

router = APIRouter()

# Initialize Firebase Admin SDK
if not firebase_admin._apps:
    # Initialize with default credentials (for development)
    # In production, use service account key file
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred)

class FCMTokenRequest(BaseModel):
    fcm_token: str
    platform: str  # 'android' or 'ios'

class NotificationRequest(BaseModel):
    user_id: Optional[str] = None
    topic: Optional[str] = None
    title: str
    body: str
    data: Optional[dict] = None

class BudgetAlertRequest(BaseModel):
    user_id: str
    category_name: str
    spent_amount: float
    budget_limit: float

class WeeklySummaryRequest(BaseModel):
    user_id: str
    weekly_income: float
    weekly_expense: float

class MonthlySummaryRequest(BaseModel):
    user_id: str
    monthly_income: float
    monthly_expense: float
    month: str

# Store FCM tokens (in production, use a proper database)
fcm_tokens = {}

@router.post("/register-token")
async def register_fcm_token(
    request: FCMTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Register FCM token for push notifications"""
    try:
        # Store the token associated with the user
        fcm_tokens[str(current_user.id)] = {
            'token': request.fcm_token,
            'platform': request.platform,
            'updated_at': datetime.utcnow()
        }
        
        return {"message": "FCM token registered successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error registering FCM token: {str(e)}")

@router.post("/send-notification")
async def send_notification(
    request: NotificationRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send push notification to user or topic"""
    try:
        if request.user_id:
            # Send to specific user
            background_tasks.add_task(
                send_notification_to_user,
                request.user_id,
                request.title,
                request.body,
                request.data or {}
            )
        elif request.topic:
            # Send to topic subscribers
            background_tasks.add_task(
                send_notification_to_topic,
                request.topic,
                request.title,
                request.body,
                request.data or {}
            )
        else:
            raise HTTPException(status_code=400, detail="Either user_id or topic must be provided")
        
        return {"message": "Notification queued for sending"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error sending notification: {str(e)}")

@router.post("/send-budget-alert")
async def send_budget_alert(
    request: BudgetAlertRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """Send budget alert notification"""
    try:
        percentage = (request.spent_amount / request.budget_limit) * 100
        
        title = "🚨 Budget Alert!"
        body = f"You've spent ${request.spent_amount:.2f} ({percentage:.1f}%) of your ${request.budget_limit:.2f} budget for {request.category_name}"
        
        data = {
            'type': 'budget_alert',
            'category_name': request.category_name,
            'spent_amount': str(request.spent_amount),
            'budget_limit': str(request.budget_limit),
            'percentage': str(percentage)
        }
        
        background_tasks.add_task(
            send_notification_to_user,
            request.user_id,
            title,
            body,
            data
        )
        
        return {"message": "Budget alert notification queued"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error sending budget alert: {str(e)}")

@router.post("/send-transaction-reminder")
async def send_transaction_reminder(
    request: dict,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """Send transaction reminder notification"""
    try:
        title = "💰 Don't Forget to Track Your Expenses!"
        body = "Take a moment to record today's transactions and keep your budget on track."
        
        data = {
            'type': 'transaction_reminder',
            'payload': 'add_transaction'
        }
        
        background_tasks.add_task(
            send_notification_to_user,
            request['user_id'],
            title,
            body,
            data
        )
        
        return {"message": "Transaction reminder notification queued"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error sending transaction reminder: {str(e)}")

@router.post("/send-weekly-summary")
async def send_weekly_summary(
    request: WeeklySummaryRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """Send weekly summary notification"""
    try:
        balance = request.weekly_income - request.weekly_expense
        status = "💚" if balance >= 0 else "🔴"
        
        title = f"{status} Weekly Summary"
        body = f"Income: ${request.weekly_income:.2f}, Expenses: ${request.weekly_expense:.2f}, Balance: ${balance:.2f}"
        
        data = {
            'type': 'weekly_summary',
            'weekly_income': str(request.weekly_income),
            'weekly_expense': str(request.weekly_expense),
            'balance': str(balance),
            'payload': 'reports'
        }
        
        background_tasks.add_task(
            send_notification_to_user,
            request.user_id,
            title,
            body,
            data
        )
        
        return {"message": "Weekly summary notification queued"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error sending weekly summary: {str(e)}")

@router.post("/send-monthly-summary")
async def send_monthly_summary(
    request: MonthlySummaryRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """Send monthly summary notification"""
    try:
        balance = request.monthly_income - request.monthly_expense
        status = "💚" if balance >= 0 else "🔴"
        
        title = f"{status} Monthly Summary - {request.month}"
        body = f"Income: ${request.monthly_income:.2f}, Expenses: ${request.monthly_expense:.2f}, Balance: ${balance:.2f}"
        
        data = {
            'type': 'monthly_summary',
            'monthly_income': str(request.monthly_income),
            'monthly_expense': str(request.monthly_expense),
            'balance': str(balance),
            'month': request.month,
            'payload': 'reports'
        }
        
        background_tasks.add_task(
            send_notification_to_user,
            request.user_id,
            title,
            body,
            data
        )
        
        return {"message": "Monthly summary notification queued"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error sending monthly summary: {str(e)}")

# Background task functions
async def send_notification_to_user(user_id: str, title: str, body: str, data: dict):
    """Send push notification to specific user"""
    try:
        if user_id not in fcm_tokens:
            print(f"No FCM token found for user {user_id}")
            return
        
        token = fcm_tokens[user_id]['token']
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data,
            token=token,
        )
        
        response = messaging.send(message)
        print(f'Successfully sent message to user {user_id}: {response}')
        
    except Exception as e:
        print(f'Error sending message to user {user_id}: {e}')
        # Remove invalid token
        if user_id in fcm_tokens:
            del fcm_tokens[user_id]

async def send_notification_to_topic(topic: str, title: str, body: str, data: dict):
    """Send push notification to topic subscribers"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data,
            topic=topic,
        )
        
        response = messaging.send(message)
        print(f'Successfully sent message to topic {topic}: {response}')
        
    except Exception as e:
        print(f'Error sending message to topic {topic}: {e}')

@router.get("/tokens")
async def get_registered_tokens(
    current_user: User = Depends(get_current_user)
):
    """Get all registered FCM tokens (admin only)"""
    # Add admin check here if needed
    return {
        "tokens": fcm_tokens,
        "total_tokens": len(fcm_tokens)
    }

@router.delete("/tokens/{user_id}")
async def remove_fcm_token(
    user_id: str,
    current_user: User = Depends(get_current_user)
):
    """Remove FCM token for user"""
    try:
        if user_id in fcm_tokens:
            del fcm_tokens[user_id]
            return {"message": f"FCM token removed for user {user_id}"}
        else:
            raise HTTPException(status_code=404, detail="FCM token not found for user")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error removing FCM token: {str(e)}")
