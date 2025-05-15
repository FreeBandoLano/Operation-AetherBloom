"""
Device models for Smart Inhaler connectivity

This module defines models for tracking device connections,
usage events, and inhaler data.
"""
from sqlalchemy import Column, ForeignKey, Integer, String, Float, DateTime, JSON, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime

from ..db.database import Base

class Device(Base):
    """Smart Inhaler device registration and metadata."""
    __tablename__ = "devices"
    
    id = Column(String, primary_key=True)  # Device ID or MAC address
    name = Column(String)
    model = Column(String)
    firmware_version = Column(String)
    last_connected = Column(DateTime, nullable=True)
    battery_level = Column(Float, default=100.0)
    is_active = Column(Boolean, default=True)
    
    # Foreign key to user
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Relationships
    usage_events = relationship("DeviceUsageEvent", back_populates="device")
    
class DeviceUsageEvent(Base):
    """Records of inhaler usage captured by the device."""
    __tablename__ = "device_usage_events"
    
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, ForeignKey("devices.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Device sensor data
    pressure_reading = Column(Float, nullable=True)
    flow_rate = Column(Float, nullable=True)
    duration_ms = Column(Integer, nullable=True)
    acceleration = Column(JSON, nullable=True)  # [x, y, z] readings
    
    # Environmental data
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    air_quality = Column(Float, nullable=True)
    
    # Location data (if enabled by user)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Related medication (if identified)
    medication_id = Column(String, ForeignKey("medications.id"), nullable=True)
    
    # Derived data
    dose_delivered = Column(Float, nullable=True)
    technique_score = Column(Float, nullable=True)
    
    # Validity flag (set to False if this is a test or false reading)
    is_valid = Column(Boolean, default=True)
    
    # Relationships
    device = relationship("Device", back_populates="usage_events")
    medication = relationship("Medication") 