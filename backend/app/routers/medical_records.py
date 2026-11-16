from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.medical_record import (
    MedicalProfileCreate, MedicalProfileResponse,
    PrescriptionCreate, PrescriptionResponse,
    VoiceNoteResponse
)
from app.services.medical_service import MedicalService
from app.core.security import get_current_user_token

router = APIRouter(prefix="/api/medical", tags=["Medical Records"])

@router.get("/profile", response_model=MedicalProfileResponse)
def get_medical_profile(
    user_id: Optional[str] = Query(None),
    token_data: Optional[dict] = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """Retrieve the current patient's medical profile including prescriptions and audio notes."""
    target_user_id = user_id or (token_data.get("sub") if token_data else "user_001")
    return MedicalService.get_profile_response(db, user_id=target_user_id)

@router.post("/profile", response_model=MedicalProfileResponse)
def save_medical_profile(
    req: MedicalProfileCreate,
    user_id: Optional[str] = Query(None),
    token_data: Optional[dict] = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """Save or update the medical profile."""
    target_user_id = user_id or (token_data.get("sub") if token_data else "user_001")
    return MedicalService.save_profile(db, req, user_id=target_user_id)

@router.post("/prescriptions", response_model=PrescriptionResponse, status_code=status.HTTP_201_CREATED)
def add_prescription(
    req: PrescriptionCreate,
    user_id: Optional[str] = Query(None),
    token_data: Optional[dict] = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """Add a new prescription to the medical profile."""
    target_user_id = user_id or (token_data.get("sub") if token_data else "user_001")
    return MedicalService.save_prescription(db, req, user_id=target_user_id)

@router.delete("/prescriptions/{prescription_id}")
def delete_prescription(
    prescription_id: str,
    token_data: Optional[dict] = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """Delete a prescription by ID."""
    user_id = token_data.get("sub") if token_data else None
    return MedicalService.delete_prescription(db, prescription_id, user_id=user_id)
