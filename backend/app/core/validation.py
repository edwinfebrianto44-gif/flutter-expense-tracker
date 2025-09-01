"""
Advanced input validation utilities
"""

import re
from decimal import Decimal, InvalidOperation
from typing import Optional, List, Any
from datetime import datetime, date
from email_validator import validate_email, EmailNotValidError
from fastapi import HTTPException, status
from pydantic import BaseModel, ValidationError


class ValidationError(Exception):
    """Custom validation error"""
    def __init__(self, message: str, field: str = None):
        self.message = message
        self.field = field
        super().__init__(self.message)


class InputValidator:
    """Comprehensive input validation class"""
    
    @staticmethod
    def validate_email_format(email: str) -> bool:
        """Validate email format using email-validator library"""
        try:
            validate_email(email)
            return True
        except EmailNotValidError:
            return False
    
    @staticmethod
    def validate_password_strength(password: str) -> tuple[bool, List[str]]:
        """
        Validate password strength
        Returns: (is_valid, list_of_errors)
        """
        errors = []
        
        if len(password) < 8:
            errors.append("Password must be at least 8 characters long")
        
        if len(password) > 128:
            errors.append("Password must not exceed 128 characters")
        
        if not re.search(r"[a-z]", password):
            errors.append("Password must contain at least one lowercase letter")
        
        if not re.search(r"[A-Z]", password):
            errors.append("Password must contain at least one uppercase letter")
        
        if not re.search(r"\d", password):
            errors.append("Password must contain at least one digit")
        
        if not re.search(r"[!@#$%^&*()_+\-=\[\]{};':\"\\|,.<>\/?]", password):
            errors.append("Password must contain at least one special character")
        
        # Check for common weak passwords
        weak_patterns = [
            r"123456",
            r"password",
            r"qwerty",
            r"abc123",
            r"admin",
            r"letmein"
        ]
        
        for pattern in weak_patterns:
            if re.search(pattern, password.lower()):
                errors.append("Password contains common weak patterns")
                break
        
        return len(errors) == 0, errors
    
    @staticmethod
    def validate_amount(amount: Any) -> bool:
        """Validate monetary amount"""
        try:
            # Convert to Decimal for precise monetary calculations
            decimal_amount = Decimal(str(amount))
            
            # Check if amount is positive
            if decimal_amount <= 0:
                return False
            
            # Check reasonable upper limit (adjust as needed)
            if decimal_amount > Decimal('999999999.99'):
                return False
            
            # Check decimal places (max 2 for currency)
            if decimal_amount.as_tuple().exponent < -2:
                return False
            
            return True
            
        except (InvalidOperation, ValueError, TypeError):
            return False
    
    @staticmethod
    def validate_required_fields(data: dict, required_fields: List[str]) -> List[str]:
        """Validate that all required fields are present and not empty"""
        missing_fields = []
        
        for field in required_fields:
            if field not in data:
                missing_fields.append(f"Field '{field}' is required")
            elif data[field] is None:
                missing_fields.append(f"Field '{field}' cannot be null")
            elif isinstance(data[field], str) and not data[field].strip():
                missing_fields.append(f"Field '{field}' cannot be empty")
        
        return missing_fields
    
    @staticmethod
    def validate_string_length(value: str, field_name: str, min_length: int = 0, max_length: int = 255) -> List[str]:
        """Validate string length constraints"""
        errors = []
        
        if len(value) < min_length:
            errors.append(f"{field_name} must be at least {min_length} characters long")
        
        if len(value) > max_length:
            errors.append(f"{field_name} must not exceed {max_length} characters")
        
        return errors
    
    @staticmethod
    def validate_date_range(start_date: Optional[date], end_date: Optional[date]) -> List[str]:
        """Validate date range constraints"""
        errors = []
        
        if start_date and end_date:
            if start_date > end_date:
                errors.append("Start date cannot be after end date")
        
        # Check if dates are not too far in the future
        max_future_date = date.today().replace(year=date.today().year + 1)
        
        if start_date and start_date > max_future_date:
            errors.append("Start date cannot be more than 1 year in the future")
        
        if end_date and end_date > max_future_date:
            errors.append("End date cannot be more than 1 year in the future")
        
        return errors
    
    @staticmethod
    def validate_transaction_date(transaction_date: date) -> List[str]:
        """Validate transaction date constraints"""
        errors = []
        
        # Don't allow transactions too far in the future
        max_future_date = date.today().replace(month=12, day=31)
        
        if transaction_date > max_future_date:
            errors.append("Transaction date cannot be more than end of current year")
        
        # Don't allow transactions too far in the past (adjust as needed)
        min_past_date = date.today().replace(year=date.today().year - 10)
        
        if transaction_date < min_past_date:
            errors.append("Transaction date cannot be more than 10 years in the past")
        
        return errors
    
    @staticmethod
    def sanitize_string(value: str) -> str:
        """Sanitize string input by removing dangerous characters"""
        if not isinstance(value, str):
            return str(value)
        
        # Remove potential script injection attempts
        dangerous_patterns = [
            r'<script[^>]*>.*?</script>',
            r'javascript:',
            r'on\w+\s*=',
            r'<iframe[^>]*>.*?</iframe>',
        ]
        
        sanitized = value
        for pattern in dangerous_patterns:
            sanitized = re.sub(pattern, '', sanitized, flags=re.IGNORECASE | re.DOTALL)
        
        # Trim whitespace
        sanitized = sanitized.strip()
        
        return sanitized
    
    @staticmethod
    def validate_category_data(category_data: dict) -> List[str]:
        """Validate category-specific data"""
        errors = []
        
        # Required fields
        required_fields = ['name', 'type']
        errors.extend(InputValidator.validate_required_fields(category_data, required_fields))
        
        if 'name' in category_data:
            # Category name validation
            name_errors = InputValidator.validate_string_length(
                category_data['name'], 'Category name', min_length=1, max_length=50
            )
            errors.extend(name_errors)
            
            # Check for valid characters in category name
            if not re.match(r'^[a-zA-Z0-9\s\-_&]+$', category_data['name']):
                errors.append("Category name contains invalid characters")
        
        if 'type' in category_data:
            # Category type validation
            valid_types = ['income', 'expense']
            if category_data['type'] not in valid_types:
                errors.append(f"Category type must be one of: {', '.join(valid_types)}")
        
        if 'color' in category_data and category_data['color']:
            # Color validation (hex color)
            if not re.match(r'^#[0-9A-Fa-f]{6}$', category_data['color']):
                errors.append("Color must be a valid hex color code (e.g., #FF0000)")
        
        return errors
    
    @staticmethod
    def validate_transaction_data(transaction_data: dict) -> List[str]:
        """Validate transaction-specific data"""
        errors = []
        
        # Required fields
        required_fields = ['amount', 'description', 'date', 'type', 'category_id']
        errors.extend(InputValidator.validate_required_fields(transaction_data, required_fields))
        
        if 'amount' in transaction_data:
            # Amount validation
            if not InputValidator.validate_amount(transaction_data['amount']):
                errors.append("Amount must be a positive number with maximum 2 decimal places")
        
        if 'description' in transaction_data:
            # Description validation
            desc_errors = InputValidator.validate_string_length(
                transaction_data['description'], 'Description', min_length=1, max_length=255
            )
            errors.extend(desc_errors)
        
        if 'date' in transaction_data:
            # Date validation
            try:
                if isinstance(transaction_data['date'], str):
                    transaction_date = datetime.strptime(transaction_data['date'], '%Y-%m-%d').date()
                else:
                    transaction_date = transaction_data['date']
                
                date_errors = InputValidator.validate_transaction_date(transaction_date)
                errors.extend(date_errors)
            except ValueError:
                errors.append("Date must be in YYYY-MM-DD format")
        
        if 'type' in transaction_data:
            # Transaction type validation
            valid_types = ['income', 'expense']
            if transaction_data['type'] not in valid_types:
                errors.append(f"Transaction type must be one of: {', '.join(valid_types)}")
        
        if 'category_id' in transaction_data:
            # Category ID validation
            try:
                category_id = int(transaction_data['category_id'])
                if category_id <= 0:
                    errors.append("Category ID must be a positive integer")
            except (ValueError, TypeError):
                errors.append("Category ID must be a valid integer")
        
        return errors


def validate_request_data(data: dict, validation_type: str) -> None:
    """
    Central validation function that raises HTTPException on validation errors
    """
    errors = []
    
    if validation_type == 'category':
        errors = InputValidator.validate_category_data(data)
    elif validation_type == 'transaction':
        errors = InputValidator.validate_transaction_data(data)
    elif validation_type == 'user_register':
        # User registration validation
        required_fields = ['email', 'password', 'full_name']
        errors.extend(InputValidator.validate_required_fields(data, required_fields))
        
        if 'email' in data and not InputValidator.validate_email_format(data['email']):
            errors.append("Invalid email format")
        
        if 'password' in data:
            is_valid, password_errors = InputValidator.validate_password_strength(data['password'])
            if not is_valid:
                errors.extend(password_errors)
        
        if 'full_name' in data:
            name_errors = InputValidator.validate_string_length(
                data['full_name'], 'Full name', min_length=2, max_length=100
            )
            errors.extend(name_errors)
    
    if errors:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "success": False,
                "message": "Validation failed",
                "errors": errors
            }
        )
