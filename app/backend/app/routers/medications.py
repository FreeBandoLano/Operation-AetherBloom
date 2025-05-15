"""
Medications router

This module provides endpoints for medication management,
including CRUD operations and adherence tracking.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional, Annotated
from uuid import uuid4
from datetime import datetime

from ..db.database import get_db
from ..schemas.medication import (
    Medication, MedicationCreate, MedicationUpdate,
    MedicationWithAdherence, AdherenceLog, AdherenceLogCreate,
    AdherenceStats
)
from ..models.medication import Medication as MedicationModel
from ..models.medication import AdherenceLog as AdherenceLogModel
from ..routers.auth import get_current_user
from ..models.user import User

router = APIRouter()

@router.get("/", response_model=List[Medication])
async def get_medications(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100
):
    """
    Get all medications for the current user.
    
    Args:
        current_user: Current authenticated user
        db: Database session
        skip: Number of records to skip (pagination)
        limit: Maximum number of records to return
        
    Returns:
        List of medications
    """
    medications = db.query(MedicationModel).filter(
        MedicationModel.user_id == current_user.id
    ).offset(skip).limit(limit).all()
    
    return medications

@router.post("/", response_model=Medication, status_code=status.HTTP_201_CREATED)
async def create_medication(
    medication: MedicationCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Create a new medication for the current user.
    
    Args:
        medication: Medication data to create
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Created medication
    """
    # Generate a unique ID for the medication
    medication_id = str(uuid4())
    
    # Convert scheduled times to JSON-compatible format
    scheduled_times_json = [{"hour": time.hour, "minute": time.minute} 
                            for time in medication.scheduled_times]
    
    db_medication = MedicationModel(
        id=medication_id,
        name=medication.name,
        description=medication.description,
        dosage=medication.dosage,
        unit=medication.unit,
        current_quantity=medication.current_quantity,
        refill_threshold=medication.refill_threshold,
        frequency=medication.frequency,
        scheduled_times=scheduled_times_json,
        weekdays=medication.weekdays,
        last_refill_date=datetime.utcnow(),
        refill_amount=medication.refill_amount,
        color=medication.color,
        user_id=current_user.id
    )
    
    db.add(db_medication)
    db.commit()
    db.refresh(db_medication)
    
    return db_medication

@router.get("/{medication_id}", response_model=MedicationWithAdherence)
async def get_medication(
    medication_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Get a specific medication by ID.
    
    Args:
        medication_id: ID of the medication to retrieve
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Medication details with adherence data
        
    Raises:
        HTTPException: If medication not found or not owned by user
    """
    medication = db.query(MedicationModel).filter(
        MedicationModel.id == medication_id,
        MedicationModel.user_id == current_user.id
    ).first()
    
    if medication is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medication not found"
        )
    
    # Calculate adherence rate and other derived fields
    adherence_logs = db.query(AdherenceLogModel).filter(
        AdherenceLogModel.medication_id == medication_id
    ).all()
    
    total_logs = len(adherence_logs)
    taken_count = sum(1 for log in adherence_logs if log.taken)
    adherence_rate = taken_count / total_logs if total_logs > 0 else 0.0
    
    # Calculate days until refill needed
    days_until_refill = -1  # Default for as-needed medications
    if medication.frequency != "as_needed":
        # Calculate based on daily doses and current quantity
        daily_doses = len(medication.scheduled_times)
        active_days = sum(1 for day in medication.weekdays if day)
        doses_per_week = daily_doses * active_days
        remaining_doses = medication.current_quantity - medication.refill_threshold
        if doses_per_week > 0:
            days_until_refill = int((remaining_doses / (doses_per_week / 7)))
    
    # Convert adherence logs to dictionary for response
    adherence_log_dict = {
        log.timestamp.isoformat(): log.taken
        for log in adherence_logs
    }
    
    # Create response with adherence data
    medication_with_adherence = {
        **medication.__dict__,
        "adherence_rate": adherence_rate,
        "days_until_refill_needed": days_until_refill,
        "needs_refill": medication.current_quantity <= medication.refill_threshold,
        "adherence_log": adherence_log_dict
    }
    
    return medication_with_adherence

@router.put("/{medication_id}", response_model=Medication)
async def update_medication(
    medication_id: str,
    medication_update: MedicationUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Update a medication's details.
    
    Args:
        medication_id: ID of the medication to update
        medication_update: Updated medication data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Updated medication
        
    Raises:
        HTTPException: If medication not found or not owned by user
    """
    db_medication = db.query(MedicationModel).filter(
        MedicationModel.id == medication_id,
        MedicationModel.user_id == current_user.id
    ).first()
    
    if db_medication is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medication not found"
        )
    
    # Update fields if provided
    update_data = medication_update.dict(exclude_unset=True)
    
    # Handle special case for scheduled_times (convert to JSON)
    if "scheduled_times" in update_data:
        update_data["scheduled_times"] = [
            {"hour": time.hour, "minute": time.minute} 
            for time in update_data["scheduled_times"]
        ]
    
    for key, value in update_data.items():
        setattr(db_medication, key, value)
    
    db.commit()
    db.refresh(db_medication)
    
    return db_medication

@router.delete("/{medication_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medication(
    medication_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Delete a medication.
    
    Args:
        medication_id: ID of the medication to delete
        current_user: Current authenticated user
        db: Database session
        
    Raises:
        HTTPException: If medication not found or not owned by user
    """
    db_medication = db.query(MedicationModel).filter(
        MedicationModel.id == medication_id,
        MedicationModel.user_id == current_user.id
    ).first()
    
    if db_medication is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medication not found"
        )
    
    # Delete associated adherence logs
    db.query(AdherenceLogModel).filter(
        AdherenceLogModel.medication_id == medication_id
    ).delete()
    
    # Delete the medication
    db.delete(db_medication)
    db.commit()
    
    return None

@router.post("/{medication_id}/refill", response_model=Medication)
async def record_refill(
    medication_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Record a medication refill.
    
    Args:
        medication_id: ID of the medication to refill
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Updated medication
        
    Raises:
        HTTPException: If medication not found or not owned by user
    """
    db_medication = db.query(MedicationModel).filter(
        MedicationModel.id == medication_id,
        MedicationModel.user_id == current_user.id
    ).first()
    
    if db_medication is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medication not found"
        )
    
    # Update quantity and refill date
    db_medication.current_quantity += db_medication.refill_amount
    db_medication.last_refill_date = datetime.utcnow()
    
    db.commit()
    db.refresh(db_medication)
    
    return db_medication

@router.post("/{medication_id}/adherence", response_model=AdherenceLog)
async def record_adherence(
    medication_id: str,
    adherence: AdherenceLogCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Record a medication adherence event (taken or missed).
    
    Args:
        medication_id: ID of the medication
        adherence: Adherence data (taken/missed)
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Created adherence log
        
    Raises:
        HTTPException: If medication not found or not owned by user
    """
    # Ensure medication exists and belongs to user
    db_medication = db.query(MedicationModel).filter(
        MedicationModel.id == medication_id,
        MedicationModel.user_id == current_user.id
    ).first()
    
    if db_medication is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medication not found"
        )
    
    # Create adherence log
    db_adherence = AdherenceLogModel(
        medication_id=medication_id,
        timestamp=adherence.timestamp,
        taken=adherence.taken,
        scheduled_time=adherence.scheduled_time,
        dosage_taken=adherence.dosage_taken
    )
    
    db.add(db_adherence)
    
    # If taken, reduce medication quantity
    if adherence.taken:
        db_medication.current_quantity = max(0, db_medication.current_quantity - 1)
    
    db.commit()
    db.refresh(db_adherence)
    
    return db_adherence

@router.get("/adherence/stats", response_model=AdherenceStats)
async def get_adherence_stats(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db),
    medication_id: Optional[str] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None
):
    """
    Get adherence statistics for the current user.
    
    Args:
        current_user: Current authenticated user
        db: Database session
        medication_id: Optional ID of specific medication to get stats for
        from_date: Optional start date for filtering
        to_date: Optional end date for filtering
        
    Returns:
        Adherence statistics
    """
    # Build base query for user's medications
    medication_query = db.query(MedicationModel).filter(
        MedicationModel.user_id == current_user.id
    )
    
    # Filter by medication ID if provided
    if medication_id:
        medication_query = medication_query.filter(MedicationModel.id == medication_id)
    
    medications = medication_query.all()
    
    # Initialize stats
    total_doses = 0
    taken_doses = 0
    medication_rates = {}
    
    # Calculate stats for each medication
    for medication in medications:
        # Build adherence log query
        log_query = db.query(AdherenceLogModel).filter(
            AdherenceLogModel.medication_id == medication.id
        )
        
        # Apply date filters if provided
        if from_date:
            log_query = log_query.filter(AdherenceLogModel.timestamp >= from_date)
        if to_date:
            log_query = log_query.filter(AdherenceLogModel.timestamp <= to_date)
        
        logs = log_query.all()
        
        if logs:
            med_taken = sum(1 for log in logs if log.taken)
            med_total = len(logs)
            total_doses += med_total
            taken_doses += med_taken
            medication_rates[medication.name] = med_taken / med_total
    
    # Calculate overall rate
    overall_rate = taken_doses / total_doses if total_doses > 0 else 0.0
    
    return {
        "overall_rate": overall_rate,
        "total_doses": total_doses,
        "taken_doses": taken_doses,
        "medication_rates": medication_rates
    } 