from typing import List, Dict, Any
from pydantic import BaseModel
from app.schemas.patient import PatientResponse

class DashboardStatsResponse(BaseModel):
    total_patients: int
    total_emergency_requests: int
    total_audio_recordings: int
    total_prescriptions: int
    emergencies_by_type: Dict[str, int]
    recent_patients: List[PatientResponse]
