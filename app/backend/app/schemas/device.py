"""
Device schemas for request/response validation

These Pydantic models define the structure and validation rules
for device-related API requests and responses.
"""
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, Field
from datetime import datetime

class DeviceBase(BaseModel):
    """Base schema with common device attributes."""
    name: str
    model: str
    firmware_version: Optional[str] = None

class DeviceCreate(DeviceBase):
    """Schema for device registration request."""
    id: str  # Device ID or MAC address
    user_id: int

class DeviceUpdate(BaseModel):
    """Schema for device update request."""
    name: Optional[str] = None
    model: Optional[str] = None
    firmware_version: Optional[str] = None
    battery_level: Optional[float] = Field(None, ge=0, le=100)
    is_active: Optional[bool] = None

class Device(DeviceBase):
    """Schema for device response."""
    id: str
    last_connected: Optional[datetime] = None
    battery_level: float
    is_active: bool
    user_id: int
    
    class Config:
        from_attributes = True

class DeviceUsageEventBase(BaseModel):
    """Base schema for device usage events."""
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    pressure_reading: Optional[float] = None
    flow_rate: Optional[float] = None
    duration_ms: Optional[int] = None
    acceleration: Optional[List[float]] = None
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    air_quality: Optional[float] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    medication_id: Optional[str] = None
    dose_delivered: Optional[float] = None
    technique_score: Optional[float] = None
    is_valid: bool = True

class DeviceUsageEventCreate(DeviceUsageEventBase):
    """Schema for creating device usage events."""
    device_id: str

class DeviceUsageEvent(DeviceUsageEventBase):
    """Schema for device usage event response."""
    id: int
    device_id: str
    
    class Config:
        from_attributes = True

class DeviceSimulatorConfig(BaseModel):
    """Schema for device simulator configuration."""
    enabled: bool = True
    interval_seconds: int = Field(10, ge=1, le=3600)
    device_id: str
    medication_id: Optional[str] = None
    generate_random_data: bool = True
    simulation_profile: str = "default"  # default, regular, random, poor_technique
    
class DeviceStats(BaseModel):
    """Schema for device usage statistics."""
    total_uses: int
    average_technique_score: float
    average_dose_delivered: float
    usage_by_time_of_day: Dict[str, int]  # "morning", "afternoon", "evening", "night"
    usage_by_day_of_week: Dict[str, int]  # "Monday", "Tuesday", etc.
    battery_history: List[Dict[str, Any]] 