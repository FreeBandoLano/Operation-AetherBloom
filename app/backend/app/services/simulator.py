"""
Smart Inhaler Simulator Service

This module simulates a Smart Inhaler device for development and testing.
It generates synthetic inhaler usage data to simulate real-world usage
patterns and allow testing without physical hardware.
"""
import random
import time
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable, Any
from uuid import uuid4
from sqlalchemy.orm import Session

from ..models.device import Device, DeviceUsageEvent
from ..models.medication import Medication, DosageUnit
from ..core.config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("inhaler_simulator")

class SimulationProfile:
    """Base class for different simulation profiles."""
    
    def __init__(self, device_id: str, medication_id: Optional[str] = None):
        self.device_id = device_id
        self.medication_id = medication_id
        
    def generate_usage_event(self) -> Dict[str, Any]:
        """Generate a simulated usage event."""
        raise NotImplementedError("Subclasses must implement this method")

class DefaultProfile(SimulationProfile):
    """Default simulation profile with realistic inhaler usage patterns."""
    
    def generate_usage_event(self) -> Dict[str, Any]:
        """
        Generate a realistic inhaler usage event.
        
        Returns:
            Dictionary with simulated device data
        """
        # Generate sensor data
        pressure = random.uniform(0.8, 1.2)  # Normalized pressure
        flow_rate = random.uniform(30, 60)  # L/min
        duration = random.randint(1500, 3000)  # milliseconds
        acceleration = [
            random.uniform(-0.5, 0.5),
            random.uniform(-0.5, 0.5),
            random.uniform(0.8, 1.2)
        ]
        
        # Generate environmental data
        temperature = random.uniform(20, 25)  # Celsius
        humidity = random.uniform(40, 60)  # Percent
        
        # Calculate technique score (0-1)
        # Based on how close to ideal the pressure, flow, and duration are
        technique_score = random.uniform(0.7, 0.95)
        
        # Calculate delivered dose (as percentage of ideal)
        dose_delivered = 1.0 * technique_score
        
        return {
            "device_id": self.device_id,
            "medication_id": self.medication_id,
            "timestamp": datetime.utcnow(),
            "pressure_reading": pressure,
            "flow_rate": flow_rate,
            "duration_ms": duration,
            "acceleration": acceleration,
            "temperature": temperature,
            "humidity": humidity,
            "dose_delivered": dose_delivered,
            "technique_score": technique_score,
            "is_valid": True
        }

class PoorTechniqueProfile(DefaultProfile):
    """Simulation profile with poor inhaler technique."""
    
    def generate_usage_event(self) -> Dict[str, Any]:
        """
        Generate an inhaler usage event with poor technique.
        
        Returns:
            Dictionary with simulated device data
        """
        # Get base event
        event = super().generate_usage_event()
        
        # Modify for poor technique
        event["pressure_reading"] = random.uniform(0.3, 0.7)
        event["flow_rate"] = random.uniform(10, 25)
        event["duration_ms"] = random.choice([
            random.randint(300, 800),     # Too short
            random.randint(4000, 6000)    # Too long
        ])
        event["technique_score"] = random.uniform(0.2, 0.5)
        event["dose_delivered"] = 1.0 * event["technique_score"]
        
        return event

class InhalerSimulator:
    """
    Smart Inhaler simulator that generates synthetic usage data.
    
    This class can be used to simulate a Bluetooth-connected Smart Inhaler
    during development, generating realistic usage patterns and data.
    """
    
    def __init__(self, db: Session):
        """
        Initialize the inhaler simulator.
        
        Args:
            db: Database session for storing simulation data
        """
        self.db = db
        self.devices: Dict[str, Device] = {}
        self.simulations: Dict[str, asyncio.Task] = {}
        self.callbacks: List[Callable[[Dict[str, Any]], None]] = []
        
        # Available simulation profiles
        self.profiles = {
            "default": DefaultProfile,
            "poor_technique": PoorTechniqueProfile
        }
        
    async def start_simulation(
        self, 
        device_id: str, 
        medication_id: Optional[str] = None,
        interval_seconds: int = settings.SIMULATOR_INTERVAL_SECONDS,
        profile_name: str = "default"
    ) -> None:
        """
        Start a device simulation.
        
        Args:
            device_id: ID of the device to simulate
            medication_id: Optional ID of associated medication
            interval_seconds: How often to generate data (seconds)
            profile_name: Which simulation profile to use
        """
        # Stop existing simulation if any
        await self.stop_simulation(device_id)
        
        # Get or create device
        device = self.db.query(Device).filter(Device.id == device_id).first()
        if device is None:
            device = Device(
                id=device_id,
                name="Simulated Smart Inhaler",
                model="AetherBloom-Sim-2025",
                firmware_version="1.0.0",
                battery_level=100.0,
                is_active=True
            )
            self.db.add(device)
            self.db.commit()
            self.db.refresh(device)
        
        self.devices[device_id] = device
        
        # Create the simulation profile
        profile_class = self.profiles.get(profile_name, DefaultProfile)
        profile = profile_class(device_id, medication_id)
        
        # Create and start simulation task
        task = asyncio.create_task(
            self._run_simulation(device_id, profile, interval_seconds)
        )
        self.simulations[device_id] = task
        
        logger.info(f"Started simulation for device {device_id}")
    
    async def stop_simulation(self, device_id: str) -> None:
        """
        Stop a device simulation.
        
        Args:
            device_id: ID of the device to stop simulating
        """
        task = self.simulations.pop(device_id, None)
        if task:
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
            logger.info(f"Stopped simulation for device {device_id}")
    
    async def stop_all_simulations(self) -> None:
        """Stop all active simulations."""
        for device_id in list(self.simulations.keys()):
            await self.stop_simulation(device_id)
    
    def register_callback(self, callback: Callable[[Dict[str, Any]], None]) -> None:
        """
        Register a callback function to receive simulated data.
        
        Args:
            callback: Function to call with each simulated event
        """
        self.callbacks.append(callback)
    
    async def _run_simulation(
        self, 
        device_id: str, 
        profile: SimulationProfile,
        interval_seconds: int
    ) -> None:
        """
        Run the simulation loop for a device.
        
        Args:
            device_id: ID of the device to simulate
            profile: Simulation profile to use
            interval_seconds: How often to generate data
        """
        device = self.devices[device_id]
        
        try:
            while True:
                # Update device
                device.last_connected = datetime.utcnow()
                device.battery_level = max(0.0, device.battery_level - 0.1)
                self.db.commit()
                
                # Generate event with 15% probability
                if random.random() < 0.15:
                    event_data = profile.generate_usage_event()
                    event = DeviceUsageEvent(**event_data)
                    self.db.add(event)
                    self.db.commit()
                    self.db.refresh(event)
                    
                    # Call registered callbacks
                    for callback in self.callbacks:
                        try:
                            callback(event_data)
                        except Exception as e:
                            logger.error(f"Error in callback: {e}")
                
                # Wait for next interval
                await asyncio.sleep(interval_seconds)
                
        except asyncio.CancelledError:
            logger.info(f"Simulation for device {device_id} was cancelled")
            raise

# Global simulator instance
_simulator: Optional[InhalerSimulator] = None

def get_simulator(db: Session) -> InhalerSimulator:
    """
    Get the global inhaler simulator instance.
    
    Args:
        db: Database session
        
    Returns:
        InhalerSimulator instance
    """
    global _simulator
    if _simulator is None:
        _simulator = InhalerSimulator(db)
    return _simulator 