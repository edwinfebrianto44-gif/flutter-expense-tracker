"""
Structured logging configuration for the expense tracker backend.
Provides JSON formatted logs with request IDs and contextual information.
"""

import json
import uuid
import logging
import sys
from datetime import datetime
from typing import Dict, Any, Optional
from contextvars import ContextVar
from fastapi import Request
import structlog


# Context variable to store request ID across async boundaries
request_id_ctx: ContextVar[Optional[str]] = ContextVar('request_id', default=None)


class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for structured logging"""
    
    def format(self, record):
        """Format log record as JSON"""
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        # Add request ID if available
        request_id = request_id_ctx.get()
        if request_id:
            log_data["request_id"] = request_id
        
        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        # Add extra fields from log record
        for key, value in record.__dict__.items():
            if key not in ["name", "msg", "args", "levelname", "levelno", "pathname", 
                          "filename", "module", "lineno", "funcName", "created", 
                          "msecs", "relativeCreated", "thread", "threadName", 
                          "processName", "process", "getMessage", "exc_info", 
                          "exc_text", "stack_info"]:
                log_data[key] = value
        
        return json.dumps(log_data, default=str)


def configure_logging(log_level: str = "INFO") -> None:
    """Configure structured logging for the application"""
    
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.StackInfoRenderer(),
            structlog.dev.set_exc_info,
            structlog.processors.JSONRenderer()
        ],
        wrapper_class=structlog.make_filtering_bound_logger(
            logging.getLevelName(log_level)
        ),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=False,
    )
    
    # Configure standard logging
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove existing handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # Add JSON formatter handler
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())
    root_logger.addHandler(handler)
    
    # Set levels for specific loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)


def generate_request_id() -> str:
    """Generate a unique request ID"""
    return str(uuid.uuid4())


def set_request_id(request_id: str) -> None:
    """Set the request ID in context"""
    request_id_ctx.set(request_id)


def get_request_id() -> Optional[str]:
    """Get the current request ID"""
    return request_id_ctx.get()


def get_logger(name: str) -> structlog.BoundLogger:
    """Get a structured logger instance"""
    return structlog.get_logger(name)


def log_request_start(request: Request, request_id: str) -> None:
    """Log the start of a request"""
    logger = get_logger("request")
    logger.info(
        "Request started",
        request_id=request_id,
        method=request.method,
        url=str(request.url),
        user_agent=request.headers.get("user-agent"),
        client_ip=request.client.host if request.client else None,
        headers={k: v for k, v in request.headers.items() 
                if k.lower() not in ["authorization", "cookie"]},
    )


def log_request_end(request: Request, response_status: int, duration: float) -> None:
    """Log the end of a request"""
    logger = get_logger("request")
    request_id = get_request_id()
    
    logger.info(
        "Request completed",
        request_id=request_id,
        method=request.method,
        url=str(request.url),
        status_code=response_status,
        duration_ms=round(duration * 1000, 2),
    )


def log_database_query(query: str, params: Dict[str, Any] = None, duration: float = None) -> None:
    """Log database queries for monitoring"""
    logger = get_logger("database")
    
    log_data = {
        "query": query[:500] + "..." if len(query) > 500 else query,  # Truncate long queries
        "request_id": get_request_id(),
    }
    
    if params:
        log_data["params"] = params
    
    if duration is not None:
        log_data["duration_ms"] = round(duration * 1000, 2)
    
    logger.info("Database query executed", **log_data)


def log_authentication_event(event_type: str, user_id: Optional[int] = None, 
                           email: Optional[str] = None, success: bool = True, 
                           reason: Optional[str] = None) -> None:
    """Log authentication events for security monitoring"""
    logger = get_logger("security")
    
    log_data = {
        "event_type": event_type,
        "success": success,
        "request_id": get_request_id(),
    }
    
    if user_id:
        log_data["user_id"] = user_id
    
    if email:
        log_data["email"] = email
    
    if reason:
        log_data["reason"] = reason
    
    if success:
        logger.info("Authentication event", **log_data)
    else:
        logger.warning("Authentication failed", **log_data)


def log_business_event(event_type: str, user_id: int, details: Dict[str, Any] = None) -> None:
    """Log business events for analytics"""
    logger = get_logger("business")
    
    log_data = {
        "event_type": event_type,
        "user_id": user_id,
        "request_id": get_request_id(),
    }
    
    if details:
        log_data.update(details)
    
    logger.info("Business event", **log_data)


def log_error(error: Exception, context: Dict[str, Any] = None) -> None:
    """Log application errors with context"""
    logger = get_logger("error")
    
    log_data = {
        "error_type": error.__class__.__name__,
        "error_message": str(error),
        "request_id": get_request_id(),
    }
    
    if context:
        log_data["context"] = context
    
    logger.error("Application error", exc_info=error, **log_data)


def log_performance_metric(metric_name: str, value: float, unit: str = "ms", 
                          tags: Dict[str, str] = None) -> None:
    """Log performance metrics"""
    logger = get_logger("metrics")
    
    log_data = {
        "metric_name": metric_name,
        "value": value,
        "unit": unit,
        "request_id": get_request_id(),
    }
    
    if tags:
        log_data["tags"] = tags
    
    logger.info("Performance metric", **log_data)


# Application-specific loggers
auth_logger = get_logger("auth")
transaction_logger = get_logger("transaction")
category_logger = get_logger("category")
file_logger = get_logger("file")
notification_logger = get_logger("notification")
report_logger = get_logger("report")
