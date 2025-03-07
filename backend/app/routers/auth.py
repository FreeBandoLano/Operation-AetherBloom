"""
Authentication router

This module provides endpoints for user authentication,
registration, and password management.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from typing import Annotated

from ..core.config import settings
from ..schemas.auth import Token, TokenPayload, LoginRequest, PasswordReset, PasswordChange
from ..schemas.user import User, UserCreate
from ..services.auth import authenticate_user, create_access_token, create_user
from ..db.database import get_db
from ..models.user import User as UserModel

router = APIRouter()

# OAuth2 scheme for token acquisition
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Session = Depends(get_db)
) -> UserModel:
    """
    Dependency to get the current authenticated user from token.
    
    Args:
        token: JWT token from Authorization header
        db: Database session
        
    Returns:
        Current authenticated user
        
    Raises:
        HTTPException: If token is invalid or user not found
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        token_data = TokenPayload(sub=int(user_id))
    except JWTError:
        raise credentials_exception
    
    user = db.query(UserModel).filter(UserModel.id == token_data.sub).first()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user"
        )
    return user

@router.post("/login", response_model=Token)
async def login_for_access_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Session = Depends(get_db)
):
    """
    OAuth2 compatible token login, get an access token for future requests.
    
    Args:
        form_data: OAuth2 password request form
        db: Database session
        
    Returns:
        JWT access token
        
    Raises:
        HTTPException: If login fails
    """
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(subject=user.id)
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }

@router.post("/register", response_model=User)
async def register_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """
    Register a new user.
    
    Args:
        user_data: User creation data
        db: Database session
        
    Returns:
        Created user
        
    Raises:
        HTTPException: If user already exists
    """
    # Check if user already exists
    existing_user = db.query(UserModel).filter(
        (UserModel.email == user_data.email) | 
        (UserModel.username == user_data.username)
    ).first()
    
    if existing_user:
        field = "email" if existing_user.email == user_data.email else "username"
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"User with this {field} already exists"
        )
    
    # Create the user
    user = create_user(
        db=db,
        email=user_data.email,
        username=user_data.username,
        password=user_data.password,
        full_name=user_data.full_name,
        role=user_data.role
    )
    
    return user

@router.get("/me", response_model=User)
async def get_current_user_info(
    current_user: Annotated[UserModel, Depends(get_current_user)]
):
    """
    Get info about the currently authenticated user.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        Current user info
    """
    return current_user

@router.post("/password/reset", status_code=status.HTTP_202_ACCEPTED)
async def request_password_reset(
    reset_data: PasswordReset,
    db: Session = Depends(get_db)
):
    """
    Request a password reset link.
    
    Args:
        reset_data: Password reset data (email)
        db: Database session
        
    Returns:
        Success message
    """
    # Check if user exists
    user = db.query(UserModel).filter(UserModel.email == reset_data.email).first()
    
    # We always return 202 even if user doesn't exist for security reasons
    # In a real implementation, send an email with reset link
    
    return {
        "message": "If this email exists in our system, a password reset link has been sent."
    }

@router.post("/password/change", status_code=status.HTTP_200_OK)
async def change_password(
    password_data: PasswordChange,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Change the password for the current user.
    
    Args:
        password_data: Password change data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Success message
        
    Raises:
        HTTPException: If current password is incorrect
    """
    if not authenticate_user(db, current_user.username, password_data.current_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )
    
    # Update password
    current_user.hashed_password = get_password_hash(password_data.new_password)
    db.commit()
    
    return {
        "message": "Password changed successfully"
    } 