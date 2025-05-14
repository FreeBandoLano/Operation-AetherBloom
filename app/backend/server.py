"""
Server launcher for AetherBloom API

This script launches the FastAPI application using Uvicorn.
It can be used for development and production with different settings.
"""
import uvicorn
import os
import argparse
from pathlib import Path

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="AetherBloom API Server")
    parser.add_argument(
        "--host", 
        type=str, 
        default="127.0.0.1", 
        help="Host IP to bind (default: 127.0.0.1)"
    )
    parser.add_argument(
        "--port", 
        type=int, 
        default=8000, 
        help="Port to bind (default: 8000)"
    )
    parser.add_argument(
        "--reload", 
        action="store_true", 
        help="Enable auto-reload for development"
    )
    parser.add_argument(
        "--workers", 
        type=int, 
        default=1, 
        help="Number of worker processes (default: 1)"
    )
    
    args = parser.parse_args()
    
    # Set environment variables if needed
    if not os.getenv("SECRET_KEY"):
        print("WARNING: Using default SECRET_KEY. Set a secure SECRET_KEY in production!")
    
    # Launch with uvicorn
    uvicorn.run(
        "app.main:app",
        host=args.host,
        port=args.port,
        reload=args.reload,
        workers=args.workers,
        log_level="info"
    )

if __name__ == "__main__":
    main() 