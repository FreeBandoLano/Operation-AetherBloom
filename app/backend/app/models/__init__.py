"""
Models package initialization

Import all models to make them available for SQLAlchemy.
"""
from .user import User, UserRole, DoctorPatientAssociation
from .medication import Medication, AdherenceLog, DosageUnit, MedicationFrequency
from .device import Device, DeviceUsageEvent

# Define exported models
__all__ = [
    "User",
    "UserRole", 
    "DoctorPatientAssociation",
    "Medication", 
    "AdherenceLog", 
    "DosageUnit", 
    "MedicationFrequency",
    "Device", 
    "DeviceUsageEvent"
] 