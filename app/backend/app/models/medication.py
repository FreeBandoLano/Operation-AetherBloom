"""
Medication model

This module defines the Medication model and related models for storing
medication data, schedules, and adherence tracking.
"""
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, JSON, Enum, Table
from sqlalchemy.orm import relationship
import enum
from datetime import datetime

from ..db.database import Base

class DosageUnit(str, enum.Enum):
    """Enumeration of medication dosage units."""
    PILL = "pill"
    ML = "ml"
    MG = "mg"
    PUFF = "puff"
    DROP = "drop"
    UNIT = "unit"

class MedicationFrequency(str, enum.Enum):
    """Enumeration of medication frequency types."""
    DAILY = "daily"
    WEEKLY = "weekly"
    AS_NEEDED = "as_needed"
    CUSTOM = "custom"

class Medication(Base):
    """
    Medication model for storing medication details and inventory.
    Mirrors the structure in the Flutter app's medication.dart model.
    """
    __tablename__ = "medications"

    id = Column(String, primary_key=True)
    name = Column(String, index=True)
    description = Column(String, nullable=True)
    dosage = Column(Float)
    unit = Column(Enum(DosageUnit))
    current_quantity = Column(Integer)
    refill_threshold = Column(Integer)
    frequency = Column(Enum(MedicationFrequency))
    
    # Store scheduled times as JSON strings of hour:minute
    scheduled_times = Column(JSON)
    
    # Store weekdays as JSON array of booleans [Sun, Mon, ..., Sat]
    weekdays = Column(JSON)
    
    last_refill_date = Column(DateTime, default=datetime.utcnow)
    refill_amount = Column(Integer)
    
    # Store colors as integer representation
    color = Column(Integer)
    
    # Foreign key to user
    user_id = Column(Integer, ForeignKey("users.id"))
    user = relationship("User", back_populates="medications")
    
    # Relationships
    adherence_logs = relationship("AdherenceLog", back_populates="medication")

class AdherenceLog(Base):
    """Log of medication adherence events (taken or skipped)."""
    __tablename__ = "adherence_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    medication_id = Column(String, ForeignKey("medications.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)
    taken = Column(Boolean)
    
    # Additional fields for analytics
    scheduled_time = Column(String)  # Format: "HH:MM"
    dosage_taken = Column(Float, nullable=True)
    
    # Relationship
    medication = relationship("Medication", back_populates="adherence_logs") 