"""
Authentication service

This module provides functions for user authentication, 
password hashing, and JWT token generation/verification.
"""
from datetime import datetime, timedelta
from typing import Optional
from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from ..core.config import settings
from ..models.user import User, UserRole
from ..schemas.auth import TokenPayload

# Setup password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(subject: int, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create a new JWT access token.
    
    Args:
        subject: User ID to encode in the token
        expires_delta: Optional custom expiration time
        
    Returns:
        JWT access token as string
    """
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a password against a hash.
    
    Args:
        plain_password: The password to verify
        hashed_password: The hash to verify against
        
    Returns:
        True if the password matches the hash, False otherwise
    """
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """
    Hash a password.
    
    Args:
        password: The password to hash
        
    Returns:
        The hashed password
    """
    return pwd_context.hash(password)

def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
    """
    Authenticate a user with username/email and password.
    
    Args:
        db: Database session
        username: Username or email to authenticate
        password: Password to verify
        
    Returns:
        User model if authentication succeeds, None otherwise
    """
    # Check if username is an email
    if "@" in username:
        user = db.query(User).filter(User.email == username).first()
    else:
        user = db.query(User).filter(User.username == username).first()
        
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user

def create_user(
    db: Session, 
    email: str,
    username: str,
    password: str,
    full_name: Optional[str] = None,
    role: UserRole = UserRole.PATIENT
) -> User:
    """
    Create a new user in the database.
    
    Args:
        db: Database session
        email: User's email
        username: User's username
        password: User's password (will be hashed)
        full_name: User's full name
        role: User's role
        
    Returns:
        The created user
    """
    hashed_password = get_password_hash(password)
    db_user = User(
        email=email,
        username=username,
        full_name=full_name,
        hashed_password=hashed_password,
        role=role,
        is_active=True
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user 