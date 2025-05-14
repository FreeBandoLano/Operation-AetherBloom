"""
AetherBloom Backend API

This is the main entry point for the AetherBloom backend API, 
which provides medication management, adherence tracking,
and analytics for the smart inhaler system.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .db.database import engine, Base
from .core.config import settings

# Import routers (to be created)
from .routers import auth, medications, adherence, analytics, simulator

# Create tables if they don't exist (in development mode)
# In production, use Alembic migrations instead
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="AetherBloom API",
    description="Backend API for the AetherBloom Smart Inhaler System",
    version="0.1.0",
)

# Set up CORS to allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(medications.router, prefix="/api/medications", tags=["Medications"])
app.include_router(adherence.router, prefix="/api/adherence", tags=["Adherence"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])
app.include_router(simulator.router, prefix="/api/simulator", tags=["Device Simulator"])

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint that confirms the API is running."""
    return {
        "message": "Welcome to the AetherBloom API",
        "version": "0.1.0",
        "status": "online",
    } 