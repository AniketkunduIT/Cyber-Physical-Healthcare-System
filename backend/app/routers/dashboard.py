from collections import Counter
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.patient import Patient
from app.models.emergency import EmergencyRequest
from app.models.audio import AudioRecord
from app.models.medical_record import Prescription
from app.schemas.dashboard import DashboardStatsResponse
from app.schemas.patient import PatientResponse

router = APIRouter(prefix="/api/dashboard", tags=["Healthcare Dashboard"])

@router.get("/stats", response_model=DashboardStatsResponse)
def get_dashboard_stats(db: Session = Depends(get_db)):
    """Retrieve system-wide healthcare statistics and real-time operational data."""
    total_patients = db.query(Patient).count()
    total_emergencies = db.query(EmergencyRequest).count()
    total_audio = db.query(AudioRecord).count()
    total_prescriptions = db.query(Prescription).count()

    # Aggregate emergency types
    patients = db.query(Patient).all()
    type_counts = Counter(p.emergency_type for p in patients if p.emergency_type)

    recent_patients = (
        db.query(Patient)
        .order_by(Patient.created_at.desc())
        .limit(5)
        .all()
    )

    recent_list = [
        PatientResponse(
            patient_id=p.patient_id,
            age=p.age,
            weight=p.weight,
            bmi=p.bmi,
            gender=p.gender,
            known_disease=p.known_disease or "",
            allergies=p.allergies or "",
            emergency_type=p.emergency_type
        )
        for p in recent_patients
    ]

    return DashboardStatsResponse(
        total_patients=total_patients,
        total_emergency_requests=total_emergencies,
        total_audio_recordings=total_audio,
        total_prescriptions=total_prescriptions,
        emergencies_by_type=dict(type_counts),
        recent_patients=recent_list
    )
