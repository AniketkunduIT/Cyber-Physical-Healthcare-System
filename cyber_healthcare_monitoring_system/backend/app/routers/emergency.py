from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.emergency import AmbulanceRequest, AmbulanceResponse, HospitalResponse
from app.services.emergency_service import EmergencyService
from app.core.security import get_current_user_token

router = APIRouter(prefix="/api/emergency", tags=["Emergency & Dispatch"])

@router.post("/request-ambulance", response_model=AmbulanceResponse)
def request_ambulance(
    req: AmbulanceRequest,
    token_data: dict = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """Dispatch the nearest emergency ambulance based on patient coordinates and triage type."""
    user_id = token_data.get("sub") if token_data else "user_001"
    return EmergencyService.request_ambulance(db, req, user_id=user_id)

@router.get("/hospitals", response_model=List[HospitalResponse])
def get_nearby_hospitals(db: Session = Depends(get_db)):
    """Retrieve list of nearby hospitals with emergency availability and contact details."""
    return EmergencyService.get_nearby_hospitals(db)
