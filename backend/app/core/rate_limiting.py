"""
Rate limiting implementation for API endpoints
"""

import time
import redis
from typing import Dict, Optional
from fastapi import Request, HTTPException, status
from collections import defaultdict, deque
import threading
from datetime import datetime, timedelta


class InMemoryRateLimiter:
    """In-memory rate limiter using sliding window approach"""
    
    def __init__(self):
        self._requests = defaultdict(deque)
        self._lock = threading.Lock()
    
    def is_allowed(self, key: str, limit: int, window_seconds: int) -> bool:
        """Check if request is allowed based on rate limit"""
        current_time = time.time()
        
        with self._lock:
            # Clean old requests outside the window
            request_times = self._requests[key]
            while request_times and request_times[0] <= current_time - window_seconds:
                request_times.popleft()
            
            # Check if limit is exceeded
            if len(request_times) >= limit:
                return False
            
            # Add current request
            request_times.append(current_time)
            return True
    
    def get_remaining_requests(self, key: str, limit: int, window_seconds: int) -> int:
        """Get remaining requests for the key"""
        current_time = time.time()
        
        with self._lock:
            request_times = self._requests[key]
            # Clean old requests
            while request_times and request_times[0] <= current_time - window_seconds:
                request_times.popleft()
            
            return max(0, limit - len(request_times))
    
    def get_reset_time(self, key: str, window_seconds: int) -> Optional[float]:
        """Get when the rate limit will reset"""
        with self._lock:
            request_times = self._requests[key]
            if not request_times:
                return None
            
            return request_times[0] + window_seconds


class RedisRateLimiter:
    """Redis-based rate limiter for production use"""
    
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        try:
            self.redis_client = redis.from_url(redis_url, decode_responses=True)
            self.redis_client.ping()  # Test connection
            self.available = True
        except:
            self.available = False
            # Fallback to in-memory
            self.fallback = InMemoryRateLimiter()
    
    def is_allowed(self, key: str, limit: int, window_seconds: int) -> bool:
        """Check if request is allowed using Redis sliding window"""
        if not self.available:
            return self.fallback.is_allowed(key, limit, window_seconds)
        
        try:
            current_time = time.time()
            pipeline = self.redis_client.pipeline()
            
            # Remove expired entries
            pipeline.zremrangebyscore(key, 0, current_time - window_seconds)
            
            # Count current entries
            pipeline.zcard(key)
            
            # Add current request
            pipeline.zadd(key, {str(current_time): current_time})
            
            # Set expiration for the key
            pipeline.expire(key, window_seconds)
            
            results = pipeline.execute()
            current_count = results[1]
            
            return current_count < limit
            
        except Exception:
            # Fallback to in-memory on Redis error
            return self.fallback.is_allowed(key, limit, window_seconds)
    
    def get_remaining_requests(self, key: str, limit: int, window_seconds: int) -> int:
        """Get remaining requests for the key"""
        if not self.available:
            return self.fallback.get_remaining_requests(key, limit, window_seconds)
        
        try:
            current_time = time.time()
            # Remove expired and count
            self.redis_client.zremrangebyscore(key, 0, current_time - window_seconds)
            current_count = self.redis_client.zcard(key)
            return max(0, limit - current_count)
        except Exception:
            return self.fallback.get_remaining_requests(key, limit, window_seconds)


class RateLimitRule:
    """Rate limit rule configuration"""
    
    def __init__(self, limit: int, window_seconds: int, key_func=None):
        self.limit = limit
        self.window_seconds = window_seconds
        self.key_func = key_func or self._default_key_func
    
    def _default_key_func(self, request: Request) -> str:
        """Default key function using client IP"""
        client_ip = self._get_client_ip(request)
        return f"rate_limit:{client_ip}"
    
    def _get_client_ip(self, request: Request) -> str:
        """Get client IP address"""
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"


class RateLimiter:
    """Main rate limiter class"""
    
    def __init__(self, redis_url: Optional[str] = None):
        if redis_url:
            self.backend = RedisRateLimiter(redis_url)
        else:
            self.backend = InMemoryRateLimiter()
        
        # Predefined rules for different endpoints
        self.rules = {
            "login": RateLimitRule(
                limit=5, 
                window_seconds=300,  # 5 attempts per 5 minutes
                key_func=lambda req: f"login:{self._get_client_ip(req)}"
            ),
            "register": RateLimitRule(
                limit=3, 
                window_seconds=3600,  # 3 attempts per hour
                key_func=lambda req: f"register:{self._get_client_ip(req)}"
            ),
            "api": RateLimitRule(
                limit=100, 
                window_seconds=3600,  # 100 requests per hour
                key_func=lambda req: f"api:{self._get_client_ip(req)}"
            ),
            "password_reset": RateLimitRule(
                limit=3, 
                window_seconds=3600,  # 3 attempts per hour
                key_func=lambda req: f"password_reset:{self._get_client_ip(req)}"
            ),
        }
    
    def _get_client_ip(self, request: Request) -> str:
        """Get client IP address"""
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"
    
    def check_rate_limit(self, request: Request, rule_name: str) -> Dict[str, any]:
        """Check rate limit for a request"""
        if rule_name not in self.rules:
            raise ValueError(f"Unknown rate limit rule: {rule_name}")
        
        rule = self.rules[rule_name]
        key = rule.key_func(request)
        
        is_allowed = self.backend.is_allowed(key, rule.limit, rule.window_seconds)
        remaining = self.backend.get_remaining_requests(key, rule.limit, rule.window_seconds)
        
        return {
            "allowed": is_allowed,
            "limit": rule.limit,
            "remaining": remaining,
            "window_seconds": rule.window_seconds,
            "key": key
        }
    
    def add_custom_rule(self, name: str, rule: RateLimitRule):
        """Add custom rate limit rule"""
        self.rules[name] = rule


# Global rate limiter instance
rate_limiter = RateLimiter()


def rate_limit(rule_name: str):
    """Decorator for rate limiting endpoints"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Get request from args/kwargs
            request = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            
            if not request:
                for value in kwargs.values():
                    if isinstance(value, Request):
                        request = value
                        break
            
            if not request:
                raise ValueError("Request object not found in function arguments")
            
            # Check rate limit
            result = rate_limiter.check_rate_limit(request, rule_name)
            
            if not result["allowed"]:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={
                        "success": False,
                        "message": "Rate limit exceeded",
                        "limit": result["limit"],
                        "window_seconds": result["window_seconds"],
                        "retry_after": result["window_seconds"]
                    },
                    headers={
                        "X-RateLimit-Limit": str(result["limit"]),
                        "X-RateLimit-Remaining": str(result["remaining"]),
                        "X-RateLimit-Reset": str(int(time.time() + result["window_seconds"])),
                        "Retry-After": str(result["window_seconds"])
                    }
                )
            
            return func(*args, **kwargs)
        return wrapper
    return decorator


def check_login_rate_limit(request: Request):
    """Check rate limit for login attempts"""
    result = rate_limiter.check_rate_limit(request, "login")
    
    if not result["allowed"]:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "success": False,
                "message": f"Too many login attempts. Try again in {result['window_seconds']} seconds.",
                "retry_after": result["window_seconds"]
            },
            headers={
                "X-RateLimit-Limit": str(result["limit"]),
                "X-RateLimit-Remaining": str(result["remaining"]),
                "Retry-After": str(result["window_seconds"])
            }
        )


def check_register_rate_limit(request: Request):
    """Check rate limit for registration attempts"""
    result = rate_limiter.check_rate_limit(request, "register")
    
    if not result["allowed"]:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "success": False,
                "message": f"Too many registration attempts. Try again in {result['window_seconds']} seconds.",
                "retry_after": result["window_seconds"]
            },
            headers={
                "X-RateLimit-Limit": str(result["limit"]),
                "X-RateLimit-Remaining": str(result["remaining"]),
                "Retry-After": str(result["window_seconds"])
            }
        )


def check_api_rate_limit(request: Request):
    """Check rate limit for general API requests"""
    result = rate_limiter.check_rate_limit(request, "api")
    
    if not result["allowed"]:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "success": False,
                "message": f"API rate limit exceeded. Try again in {result['window_seconds']} seconds.",
                "retry_after": result["window_seconds"]
            },
            headers={
                "X-RateLimit-Limit": str(result["limit"]),
                "X-RateLimit-Remaining": str(result["remaining"]),
                "Retry-After": str(result["window_seconds"])
            }
        )
