"""
User schemas for request/response validation

These Pydantic models define the structure and validation rules
for user-related API requests and responses.
"""
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field

from ..models.user import UserRole

class UserBase(BaseModel):
    """Base schema with common user attributes."""
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    role: Optional[UserRole] = UserRole.PATIENT

class UserCreate(UserBase):
    """Schema for user creation request."""
    password: str = Field(..., min_length=8)

class UserUpdate(BaseModel):
    """Schema for user update request."""
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    password: Optional[str] = Field(None, min_length=8)
    
class UserInDB(UserBase):
    """Schema for user stored in database (includes hashed password)."""
    id: int
    hashed_password: str
    is_active: bool
    
    class Config:
        from_attributes = True

class User(UserBase):
    """Schema for user response."""
    id: int
    is_active: bool
    
    class Config:
        from_attributes = True

class UserWithRelations(User):
    """Schema for user with related doctors/patients."""
    doctors: List["UserBasic"] = []
    patients: List["UserBasic"] = []
    
    class Config:
        from_attributes = True

class UserBasic(BaseModel):
    """Simplified user schema for references."""
    id: int
    username: str
    full_name: Optional[str] = None
    role: UserRole
    
    class Config:
        from_attributes = True

# Update forward references
UserWithRelations.update_forward_refs() 