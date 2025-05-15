"""
User model for authentication and profile management

This module defines the User model with patient and doctor roles.
"""
from sqlalchemy import Boolean, Column, Integer, String, Enum
from sqlalchemy.orm import relationship
import enum

from ..db.database import Base

class UserRole(str, enum.Enum):
    """User role enumeration for access control."""
    PATIENT = "patient"
    DOCTOR = "doctor"
    ADMIN = "admin"

class User(Base):
    """User model for authentication and profile information."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    full_name = Column(String)
    hashed_password = Column(String)
    role = Column(Enum(UserRole), default=UserRole.PATIENT)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    medications = relationship("Medication", back_populates="user")
    # If a doctor, these are their patients
    patients = relationship(
        "User",
        secondary="doctor_patient_association",
        primaryjoin="User.id==DoctorPatientAssociation.doctor_id",
        secondaryjoin="User.id==DoctorPatientAssociation.patient_id",
        back_populates="doctors"
    )
    # If a patient, these are their doctors
    doctors = relationship(
        "User",
        secondary="doctor_patient_association",
        primaryjoin="User.id==DoctorPatientAssociation.patient_id",
        secondaryjoin="User.id==DoctorPatientAssociation.doctor_id",
        back_populates="patients"
    )

class DoctorPatientAssociation(Base):
    """Association table for doctor-patient relationships."""
    __tablename__ = "doctor_patient_association"
    
    doctor_id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, primary_key=True, index=True) 