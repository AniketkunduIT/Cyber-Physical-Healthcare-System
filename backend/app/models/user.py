from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String(64), primary_key=True, index=True)
    name = Column(String(128), nullable=False)
    username_or_phone = Column(String(128), unique=True, index=True, nullable=False)
    email = Column(String(128), unique=True, index=True, nullable=True)
    hashed_password = Column(String(256), nullable=False)
    role = Column(String(32), default="patient", nullable=False)  # patient, doctor, admin
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    patients = relationship("Patient", back_populates="user", cascade="all, delete-orphan")
    medical_profiles = relationship("MedicalProfile", back_populates="user", cascade="all, delete-orphan")
    audio_records = relationship("AudioRecord", back_populates="user")
