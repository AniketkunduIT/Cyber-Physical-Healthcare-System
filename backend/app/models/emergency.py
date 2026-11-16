from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime
from app.database import Base

class Hospital(Base):
    __tablename__ = "hospitals"

    id = Column(String(32), primary_key=True)
    name = Column(String(128), nullable=False)
    address = Column(String(256), nullable=False)
    distance_km = Column(Float, nullable=False, default=1.0)
    phone = Column(String(32), nullable=False)
    has_emergency_beds = Column(Boolean, nullable=False, default=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

class EmergencyRequest(Base):
    __tablename__ = "emergency_requests"

    id = Column(String(64), primary_key=True, default=lambda: f"emg_{uuid.uuid4().hex[:12]}")
    user_id = Column(String(64), nullable=True, index=True)
    patient_id = Column(String(32), nullable=True, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    emergency_type_id = Column(String(64), nullable=False)
    status = Column(String(32), nullable=False, default="assigned")
    driver_name = Column(String(128), nullable=False, default="Rakesh Sharma")
    vehicle_number = Column(String(64), nullable=False, default="KA 01 EM 1234")
    eta_minutes = Column(Integer, nullable=False, default=7)
    equipment = Column(String(512), nullable=False, default="Oxygen, Ventilator, ICU support")
    driver_phone = Column(String(32), nullable=False, default="+919876543210")
    medical_team_phone = Column(String(32), nullable=False, default="+919812345678")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
