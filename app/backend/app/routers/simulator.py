"""
Device Simulator Router

This module provides endpoints for controlling the Smart Inhaler simulator,
which generates synthetic usage data for development and testing.
"""
from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional, Annotated
from uuid import uuid4

from ..db.database import get_db
from ..services.simulator import get_simulator
from ..schemas.device import (
    DeviceSimulatorConfig, Device, DeviceCreate, 
    DeviceUsageEvent, DeviceStats
)
from ..models.device import Device as DeviceModel
from ..models.device import DeviceUsageEvent as DeviceUsageEventModel
from ..routers.auth import get_current_user
from ..models.user import User, UserRole

router = APIRouter()

@router.post("/start", status_code=status.HTTP_202_ACCEPTED)
async def start_simulation(
    config: DeviceSimulatorConfig,
    background_tasks: BackgroundTasks,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Start a Smart Inhaler simulation.
    
    Args:
        config: Simulator configuration
        background_tasks: FastAPI background tasks
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Status message
    """
    # Check if user has permission
    if current_user.role != UserRole.ADMIN and current_user.role != UserRole.DOCTOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins and doctors can control the simulator"
        )
    
    # Register device with user if not already registered
    device = db.query(DeviceModel).filter(DeviceModel.id == config.device_id).first()
    if device is None:
        device = DeviceModel(
            id=config.device_id,
            name="Simulated Smart Inhaler",
            model="AetherBloom-Sim-2025",
            firmware_version="1.0.0",
            battery_level=100.0,
            is_active=True,
            user_id=current_user.id
        )
        db.add(device)
        db.commit()
    
    # Get simulator and start simulation in background
    simulator = get_simulator(db)
    
    # Add to background tasks (will run after response is sent)
    background_tasks.add_task(
        simulator.start_simulation,
        device_id=config.device_id,
        medication_id=config.medication_id,
        interval_seconds=config.interval_seconds,
        profile_name=config.simulation_profile
    )
    
    return {
        "message": f"Simulation for device {config.device_id} started",
        "device_id": config.device_id,
        "profile": config.simulation_profile
    }

@router.post("/stop/{device_id}", status_code=status.HTTP_202_ACCEPTED)
async def stop_simulation(
    device_id: str,
    background_tasks: BackgroundTasks,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Stop a Smart Inhaler simulation.
    
    Args:
        device_id: ID of the device to stop simulating
        background_tasks: FastAPI background tasks
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Status message
    """
    # Check if user has permission
    if current_user.role != UserRole.ADMIN and current_user.role != UserRole.DOCTOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins and doctors can control the simulator"
        )
    
    # Get simulator and stop simulation in background
    simulator = get_simulator(db)
    
    # Add to background tasks
    background_tasks.add_task(simulator.stop_simulation, device_id)
    
    return {
        "message": f"Simulation for device {device_id} stopped"
    }

@router.get("/devices", response_model=List[Device])
async def get_simulated_devices(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Get all simulated devices.
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        List of simulated devices
    """
    if current_user.role == UserRole.ADMIN:
        # Admins can see all devices
        devices = db.query(DeviceModel).all()
    else:
        # Regular users only see their own devices
        devices = db.query(DeviceModel).filter(
            DeviceModel.user_id == current_user.id
        ).all()
    
    return devices

@router.get("/events/{device_id}", response_model=List[DeviceUsageEvent])
async def get_device_events(
    device_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db),
    limit: int = 50
):
    """
    Get simulated usage events for a device.
    
    Args:
        device_id: ID of the device to get events for
        current_user: Current authenticated user
        db: Database session
        limit: Maximum number of events to return
        
    Returns:
        List of device usage events
    """
    # Check device ownership or admin status
    device = db.query(DeviceModel).filter(DeviceModel.id == device_id).first()
    if device is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )
    
    if device.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this device's data"
        )
    
    # Get events
    events = db.query(DeviceUsageEventModel).filter(
        DeviceUsageEventModel.device_id == device_id
    ).order_by(DeviceUsageEventModel.timestamp.desc()).limit(limit).all()
    
    return events

@router.get("/stats/{device_id}", response_model=DeviceStats)
async def get_device_statistics(
    device_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Get usage statistics for a simulated device.
    
    Args:
        device_id: ID of the device to get stats for
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Device usage statistics
    """
    # Check device ownership or admin status
    device = db.query(DeviceModel).filter(DeviceModel.id == device_id).first()
    if device is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )
    
    if device.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this device's data"
        )
    
    # Get all events for this device
    events = db.query(DeviceUsageEventModel).filter(
        DeviceUsageEventModel.device_id == device_id
    ).all()
    
    # Calculate statistics
    total_uses = len(events)
    
    # Default values if no events
    if total_uses == 0:
        return {
            "total_uses": 0,
            "average_technique_score": 0.0,
            "average_dose_delivered": 0.0,
            "usage_by_time_of_day": {},
            "usage_by_day_of_week": {},
            "battery_history": []
        }
    
    # Calculate averages
    avg_technique = sum(e.technique_score or 0 for e in events) / total_uses
    avg_dose = sum(e.dose_delivered or 0 for e in events) / total_uses
    
    # Categorize by time of day
    time_categories = {
        "morning": 0,   # 6:00-11:59
        "afternoon": 0, # 12:00-17:59
        "evening": 0,   # 18:00-21:59
        "night": 0      # 22:00-5:59
    }
    
    for event in events:
        hour = event.timestamp.hour
        if 6 <= hour < 12:
            time_categories["morning"] += 1
        elif 12 <= hour < 18:
            time_categories["afternoon"] += 1
        elif 18 <= hour < 22:
            time_categories["evening"] += 1
        else:
            time_categories["night"] += 1
    
    # Categorize by day of week
    days_of_week = {
        "Monday": 0,
        "Tuesday": 0,
        "Wednesday": 0,
        "Thursday": 0,
        "Friday": 0,
        "Saturday": 0,
        "Sunday": 0
    }
    
    day_names = list(days_of_week.keys())
    for event in events:
        day_idx = event.timestamp.weekday()  # 0 = Monday
        days_of_week[day_names[day_idx]] += 1
    
    # Get battery history (from device updates)
    # In a real implementation, this would have more granularity
    battery_history = [
        {
            "timestamp": device.last_connected.isoformat() if device.last_connected else datetime.utcnow().isoformat(),
            "level": device.battery_level
        }
    ]
    
    return {
        "total_uses": total_uses,
        "average_technique_score": avg_technique,
        "average_dose_delivered": avg_dose,
        "usage_by_time_of_day": time_categories,
        "usage_by_day_of_week": days_of_week,
        "battery_history": battery_history
    }

@router.post("/generate_event", response_model=DeviceUsageEvent, status_code=status.HTTP_201_CREATED)
async def generate_single_event(
    device_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db),
    medication_id: Optional[str] = None,
    profile_name: str = "default"
):
    """
    Generate a single simulated usage event on demand.
    
    Args:
        device_id: ID of the device to generate an event for
        current_user: Current authenticated user
        db: Database session
        medication_id: Optional ID of associated medication
        profile_name: Simulation profile to use
        
    Returns:
        Generated device usage event
    """
    # Check permission
    if current_user.role != UserRole.ADMIN and current_user.role != UserRole.DOCTOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins and doctors can generate events"
        )
    
    # Check device ownership or admin status
    device = db.query(DeviceModel).filter(DeviceModel.id == device_id).first()
    if device is None:
        # Create device if it doesn't exist
        device = DeviceModel(
            id=device_id,
            name="Simulated Smart Inhaler",
            model="AetherBloom-Sim-2025",
            firmware_version="1.0.0",
            battery_level=100.0,
            is_active=True,
            user_id=current_user.id
        )
        db.add(device)
        db.commit()
        db.refresh(device)
    elif device.user_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this device"
        )
    
    # Get simulator
    simulator = get_simulator(db)
    
    # Create profile and generate event
    profile_class = simulator.profiles.get(profile_name, simulator.profiles["default"])
    profile = profile_class(device_id, medication_id)
    event_data = profile.generate_usage_event()
    
    # Create event in database
    event = DeviceUsageEventModel(**event_data)
    db.add(event)
    db.commit()
    db.refresh(event)
    
    return event 