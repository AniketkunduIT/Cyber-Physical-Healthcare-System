from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class AudioRecord(Base):
    __tablename__ = "audio_records"

    id = Column(String(64), primary_key=True, default=lambda: f"aud_{uuid.uuid4().hex[:12]}")
    audio_id = Column(String(64), unique=True, index=True, nullable=False)
    user_id = Column(String(64), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    patient_id = Column(String(32), ForeignKey("patients.patient_id", ondelete="SET NULL"), nullable=True, index=True)
    medical_profile_id = Column(String(64), ForeignKey("medical_profiles.id", ondelete="SET NULL"), nullable=True, index=True)
    filename = Column(String(256), unique=True, nullable=False)
    original_filename = Column(String(256), nullable=False)
    file_path = Column(String(512), nullable=False)
    mime_type = Column(String(128), nullable=False)
    file_size = Column(Integer, nullable=False, default=0)
    duration_seconds = Column(Integer, nullable=False, default=0)
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    user = relationship("User", back_populates="audio_records")
    patient = relationship("Patient", back_populates="audio_records")
    medical_profile = relationship("MedicalProfile", back_populates="audio_records")
