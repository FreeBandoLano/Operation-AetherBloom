"""
Authentication schemas for request/response validation

These Pydantic models define the structure and validation rules
for authentication-related API requests and responses.
"""
from typing import Optional
from pydantic import BaseModel, EmailStr

class Token(BaseModel):
    """Schema for authentication token response."""
    access_token: str
    token_type: str = "bearer"
    
class TokenPayload(BaseModel):
    """Schema for token payload (JWT claims)."""
    sub: Optional[int] = None  # Subject (user ID)
    
class LoginRequest(BaseModel):
    """Schema for login request (username/email + password)."""
    username: str  # Can be email or username
    password: str
    
class PasswordReset(BaseModel):
    """Schema for password reset request."""
    email: EmailStr
    
class PasswordChange(BaseModel):
    """Schema for password change request."""
    current_password: str
    new_password: str 