"""
Health check and monitoring endpoints for the expense tracker API.
"""

import psutil
import time
from datetime import datetime, timedelta
from typing import Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from ..core.database import get_db
from ..core.logging import get_logger
from ..models.user import User
from ..models.transaction import Transaction
from ..models.category import Category

router = APIRouter()
logger = get_logger("health")


@router.get(
    "/healthz",
    summary="Health check endpoint",
    description="Basic health check endpoint for load balancers and monitoring systems",
    tags=["Health Check"],
    response_model=dict
)
async def health_check():
    """Basic health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "version": "1.0.0"
    }


@router.get(
    "/health",
    summary="Detailed health check",
    description="Detailed health check with system and database status",
    tags=["Health Check"],
    response_model=dict
)
async def detailed_health_check(db: Session = Depends(get_db)):
    """Detailed health check with dependencies"""
    start_time = time.time()
    
    health_data = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "version": "1.0.0",
        "checks": {}
    }
    
    # Database health check
    try:
        db_start = time.time()
        result = db.execute(text("SELECT 1")).scalar()
        db_duration = (time.time() - db_start) * 1000
        
        health_data["checks"]["database"] = {
            "status": "healthy" if result == 1 else "unhealthy",
            "response_time_ms": round(db_duration, 2)
        }
    except Exception as e:
        logger.error("Database health check failed", error=str(e), exc_info=e)
        health_data["checks"]["database"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        health_data["status"] = "degraded"
    
    # System resources check
    try:
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        health_data["checks"]["system"] = {
            "status": "healthy",
            "cpu_percent": psutil.cpu_percent(interval=0.1),
            "memory_percent": memory.percent,
            "disk_percent": disk.percent,
            "memory_available_mb": round(memory.available / 1024 / 1024, 2),
            "disk_free_gb": round(disk.free / 1024 / 1024 / 1024, 2)
        }
        
        # Mark as degraded if resources are high
        if memory.percent > 90 or disk.percent > 90:
            health_data["checks"]["system"]["status"] = "degraded"
            health_data["status"] = "degraded"
            
    except Exception as e:
        logger.error("System health check failed", error=str(e), exc_info=e)
        health_data["checks"]["system"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        health_data["status"] = "degraded"
    
    # Application-specific checks
    try:
        app_start = time.time()
        
        # Check if we can query basic models
        user_count = db.query(User).count()
        transaction_count = db.query(Transaction).count()
        category_count = db.query(Category).count()
        
        app_duration = (time.time() - app_start) * 1000
        
        health_data["checks"]["application"] = {
            "status": "healthy",
            "response_time_ms": round(app_duration, 2),
            "stats": {
                "total_users": user_count,
                "total_transactions": transaction_count,
                "total_categories": category_count
            }
        }
        
    except Exception as e:
        logger.error("Application health check failed", error=str(e), exc_info=e)
        health_data["checks"]["application"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        health_data["status"] = "degraded"
    
    # Overall response time
    total_duration = (time.time() - start_time) * 1000
    health_data["response_time_ms"] = round(total_duration, 2)
    
    # Log health check
    logger.info(
        "Health check completed",
        status=health_data["status"],
        response_time_ms=health_data["response_time_ms"],
        checks={k: v.get("status", "unknown") for k, v in health_data["checks"].items()}
    )
    
    # Return appropriate HTTP status
    if health_data["status"] == "unhealthy":
        raise HTTPException(status_code=503, detail=health_data)
    
    return health_data


@router.get(
    "/metrics",
    summary="Application metrics",
    description="Application metrics in Prometheus format (optional)",
    tags=["Metrics"],
    response_model=str
)
async def get_metrics(db: Session = Depends(get_db)):
    """Get application metrics in Prometheus format"""
    try:
        # Get database statistics
        user_count = db.query(User).count()
        active_users = db.query(User).filter(User.is_active == True).count()
        transaction_count = db.query(Transaction).count()
        category_count = db.query(Category).count()
        
        # Get recent activity (last 24 hours)
        yesterday = datetime.utcnow() - timedelta(days=1)
        recent_transactions = db.query(Transaction).filter(
            Transaction.created_at >= yesterday
        ).count()
        
        recent_users = db.query(User).filter(
            User.last_login >= yesterday
        ).count() if db.query(User).filter(User.last_login.isnot(None)).count() > 0 else 0
        
        # System metrics
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        cpu_percent = psutil.cpu_percent(interval=0.1)
        
        # Format as Prometheus metrics
        metrics = f"""# HELP expense_tracker_users_total Total number of registered users
# TYPE expense_tracker_users_total counter
expense_tracker_users_total {user_count}

# HELP expense_tracker_users_active Number of active users
# TYPE expense_tracker_users_active gauge
expense_tracker_users_active {active_users}

# HELP expense_tracker_transactions_total Total number of transactions
# TYPE expense_tracker_transactions_total counter
expense_tracker_transactions_total {transaction_count}

# HELP expense_tracker_categories_total Total number of categories
# TYPE expense_tracker_categories_total counter
expense_tracker_categories_total {category_count}

# HELP expense_tracker_transactions_24h Transactions created in last 24 hours
# TYPE expense_tracker_transactions_24h gauge
expense_tracker_transactions_24h {recent_transactions}

# HELP expense_tracker_active_users_24h Users active in last 24 hours
# TYPE expense_tracker_active_users_24h gauge
expense_tracker_active_users_24h {recent_users}

# HELP expense_tracker_system_memory_percent Memory usage percentage
# TYPE expense_tracker_system_memory_percent gauge
expense_tracker_system_memory_percent {memory.percent}

# HELP expense_tracker_system_disk_percent Disk usage percentage
# TYPE expense_tracker_system_disk_percent gauge
expense_tracker_system_disk_percent {disk.percent}

# HELP expense_tracker_system_cpu_percent CPU usage percentage
# TYPE expense_tracker_system_cpu_percent gauge
expense_tracker_system_cpu_percent {cpu_percent}

# HELP expense_tracker_system_memory_available_bytes Available memory in bytes
# TYPE expense_tracker_system_memory_available_bytes gauge
expense_tracker_system_memory_available_bytes {memory.available}

# HELP expense_tracker_system_disk_free_bytes Free disk space in bytes
# TYPE expense_tracker_system_disk_free_bytes gauge
expense_tracker_system_disk_free_bytes {disk.free}
"""
        
        logger.info("Metrics retrieved", user_count=user_count, transaction_count=transaction_count)
        
        return metrics
        
    except Exception as e:
        logger.error("Failed to retrieve metrics", error=str(e), exc_info=e)
        raise HTTPException(status_code=500, detail="Failed to retrieve metrics")


@router.get(
    "/ready",
    summary="Readiness probe",
    description="Readiness probe for Kubernetes deployments",
    tags=["Health Check"],
    response_model=dict
)
async def readiness_probe(db: Session = Depends(get_db)):
    """Readiness probe - checks if app is ready to serve traffic"""
    try:
        # Check database connectivity
        db.execute(text("SELECT 1")).scalar()
        
        return {
            "status": "ready",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
    except Exception as e:
        logger.error("Readiness probe failed", error=str(e), exc_info=e)
        raise HTTPException(
            status_code=503,
            detail={
                "status": "not_ready",
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }
        )


@router.get(
    "/live",
    summary="Liveness probe",
    description="Liveness probe for Kubernetes deployments",
    tags=["Health Check"],
    response_model=dict
)
async def liveness_probe():
    """Liveness probe - checks if app is alive"""
    return {
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
