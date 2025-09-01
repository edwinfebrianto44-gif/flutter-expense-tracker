from typing import Dict, Any, Optional


def create_response(
    status: str = "success",
    message: str = "",
    data: Any = None,
    meta: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Create standardized API response
    
    Args:
        status: "success" or "error"
        message: Human readable message
        data: Response data
        meta: Additional metadata (pagination, etc.)
    
    Returns:
        Dict containing standardized response
    """
    response = {
        "status": status,
        "message": message,
        "data": data
    }
    
    if meta:
        response["meta"] = meta
        
    return response


def success_response(message: str = "", data: Any = None, meta: Optional[Dict[str, Any]] = None):
    """Create success response"""
    return create_response("success", message, data, meta)


def error_response(message: str = "", data: Any = None):
    """Create error response"""
    return create_response("error", message, data)
