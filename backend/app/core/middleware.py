"""
Logging middleware for FastAPI to add request ID and structured logging.
"""

import time
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
from .logging import (
    generate_request_id, 
    set_request_id, 
    log_request_start, 
    log_request_end,
    get_logger
)


class LoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to add request logging and request ID tracking"""
    
    def __init__(self, app: ASGIApp):
        super().__init__(app)
        self.logger = get_logger("middleware")
    
    async def dispatch(self, request: Request, call_next):
        # Generate and set request ID
        request_id = generate_request_id()
        set_request_id(request_id)
        
        # Add request ID to request state for access in endpoints
        request.state.request_id = request_id
        
        # Record start time
        start_time = time.time()
        
        # Log request start
        log_request_start(request, request_id)
        
        # Process request
        try:
            response = await call_next(request)
            
            # Calculate duration
            duration = time.time() - start_time
            
            # Log request completion
            log_request_end(request, response.status_code, duration)
            
            # Add request ID to response headers
            response.headers["X-Request-ID"] = request_id
            
            return response
            
        except Exception as e:
            # Calculate duration for failed requests
            duration = time.time() - start_time
            
            # Log the error
            self.logger.error(
                "Request failed with exception",
                request_id=request_id,
                method=request.method,
                url=str(request.url),
                duration_ms=round(duration * 1000, 2),
                error=str(e),
                exc_info=e
            )
            
            # Re-raise the exception
            raise
