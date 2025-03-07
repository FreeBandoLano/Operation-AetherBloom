"""
Medication schemas for request/response validation

These Pydantic models define the structure and validation rules
for medication-related API requests and responses.
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime, time

from ..models.medication import DosageUnit, MedicationFrequency

class ScheduledTime(BaseModel):
    """Schema for representing a scheduled medication time."""
    hour: int = Field(..., ge=0, le=23)
    minute: int = Field(..., ge=0, le=59)

class MedicationBase(BaseModel):
    """Base schema with common medication attributes."""
    name: str
    description: Optional[str] = None
    dosage: float = Field(..., gt=0)
    unit: DosageUnit
    current_quantity: int = Field(..., ge=0)
    refill_threshold: int = Field(..., ge=0)
    frequency: MedicationFrequency
    scheduled_times: List[ScheduledTime]
    weekdays: List[bool] = Field(..., min_items=7, max_items=7)
    refill_amount: int = Field(..., gt=0)
    color: int

class MedicationCreate(MedicationBase):
    """Schema for medication creation request."""
    pass

class MedicationUpdate(BaseModel):
    """Schema for medication update request."""
    name: Optional[str] = None
    description: Optional[str] = None
    dosage: Optional[float] = Field(None, gt=0)
    unit: Optional[DosageUnit] = None
    current_quantity: Optional[int] = Field(None, ge=0)
    refill_threshold: Optional[int] = Field(None, ge=0)
    frequency: Optional[MedicationFrequency] = None
    scheduled_times: Optional[List[ScheduledTime]] = None
    weekdays: Optional[List[bool]] = Field(None, min_items=7, max_items=7)
    refill_amount: Optional[int] = Field(None, gt=0)
    color: Optional[int] = None

class Medication(MedicationBase):
    """Schema for medication response."""
    id: str
    last_refill_date: datetime
    user_id: int
    
    class Config:
        from_attributes = True

class MedicationWithAdherence(Medication):
    """Schema for medication with adherence data."""
    adherence_rate: float
    days_until_refill_needed: int
    needs_refill: bool
    adherence_log: Dict[str, bool]
    
    class Config:
        from_attributes = True

class AdherenceLogBase(BaseModel):
    """Base schema for adherence log entries."""
    timestamp: datetime
    taken: bool
    scheduled_time: Optional[str] = None
    dosage_taken: Optional[float] = None

class AdherenceLogCreate(AdherenceLogBase):
    """Schema for creating adherence log entries."""
    medication_id: str

class AdherenceLog(AdherenceLogBase):
    """Schema for adherence log response."""
    id: int
    medication_id: str
    
    class Config:
        from_attributes = True

class AdherenceStats(BaseModel):
    """Schema for adherence statistics."""
    overall_rate: float
    total_doses: int
    taken_doses: int
    medication_rates: Dict[str, float]
    
    class Config:
        from_attributes = True 