from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.database import Base

class MedicalProfile(Base):
    __tablename__ = "medical_profiles"

    id = Column(String(64), primary_key=True, default=lambda: f"mp_{uuid.uuid4().hex[:12]}")
    user_id = Column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    patient_id = Column(String(32), nullable=True)
    age = Column(Integer, nullable=True)
    weight_kg = Column(Float, nullable=True)
    gender = Column(String(32), nullable=True)
    known_diseases = Column(Text, nullable=False, default="")
    allergies = Column(Text, nullable=False, default="")
    selected_emergency_type_id = Column(String(64), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    user = relationship("User", back_populates="medical_profiles")
    prescriptions = relationship("Prescription", back_populates="medical_profile", cascade="all, delete-orphan")
    audio_records = relationship("AudioRecord", back_populates="medical_profile", cascade="all, delete-orphan")

class Prescription(Base):
    __tablename__ = "prescriptions"

    id = Column(String(64), primary_key=True, default=lambda: f"pres_{uuid.uuid4().hex[:12]}")
    medical_profile_id = Column(String(64), ForeignKey("medical_profiles.id", ondelete="CASCADE"), nullable=True, index=True)
    user_id = Column(String(64), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    file_name = Column(String(256), nullable=False)
    file_size_bytes = Column(Integer, nullable=False, default=0)
    doctor_name = Column(String(128), nullable=False, default="")
    prescription_date = Column(String(64), nullable=False, default="")
    medicines_notes = Column(Text, nullable=False, default="")
    uploaded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    medical_profile = relationship("MedicalProfile", back_populates="prescriptions")
