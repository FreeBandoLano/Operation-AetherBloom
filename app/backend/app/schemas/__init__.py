"""
Schemas package initialization

Import all Pydantic schemas to make them available.
"""
from .user import (
    User, UserCreate, UserUpdate, UserInDB, 
    UserWithRelations, UserBasic
)
from .medication import (
    Medication, MedicationCreate, MedicationUpdate,
    MedicationWithAdherence, AdherenceLog, AdherenceLogCreate,
    AdherenceStats, ScheduledTime
)
from .device import (
    Device, DeviceCreate, DeviceUpdate,
    DeviceUsageEvent, DeviceUsageEventCreate, DeviceUsageEventBase,
    DeviceSimulatorConfig, DeviceStats
)
from .auth import Token, TokenPayload, LoginRequest, PasswordReset, PasswordChange 