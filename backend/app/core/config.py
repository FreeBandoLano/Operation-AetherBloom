"""
Application configuration and settings

This module handles environment variables and application settings.
"""
import os
from typing import List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # API Settings
    API_V1_STR: str = "/api"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "temporarysecretkey")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:8000",  # FastAPI Swagger UI
        "http://localhost:3000",  # Frontend (if separate)
        "*",  # For development only, remove in production
    ]
    
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", "sqlite:///./aetherbloom.db"
    )
    
    # Device Simulator Settings
    SIMULATOR_ENABLED: bool = True
    SIMULATOR_INTERVAL_SECONDS: int = 10
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Create settings instance
settings = Settings() 