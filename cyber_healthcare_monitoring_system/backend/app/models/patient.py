from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String(32), unique=True, index=True, nullable=False)
    user_id = Column(String(64), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    name = Column(String(128), nullable=True)
    age = Column(Integer, nullable=False)
    weight = Column(Float, nullable=False)
    bmi = Column(Float, nullable=True)
    gender = Column(String(32), nullable=False)
    known_disease = Column(String(256), nullable=True, default="")
    allergies = Column(String(256), nullable=True, default="")
    emergency_type = Column(String(64), nullable=False, default="unspecified")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    user = relationship("User", back_populates="patients")
    audio_records = relationship("AudioRecord", back_populates="patient")
