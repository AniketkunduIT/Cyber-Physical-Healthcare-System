from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.patient import PatientCreate, PatientUpdate, PatientResponse
from app.services.patient_service import PatientService

router = APIRouter(tags=["Patient Management"])

# --- Modular Endpoints under /api/patients ---

@router.post("/api/patients", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
def create_patient_api(req: PatientCreate, db: Session = Depends(get_db)):
    """Create a new patient record."""
    return PatientService.create_patient(db, req)

@router.get("/api/patients", response_model=List[PatientResponse])
def get_patients_api(
    skip: int = Query(0, ge=0),
    limit: int = Query(200, ge=1, le=500),
    db: Session = Depends(get_db)
):
    """Retrieve all patient records."""
    return PatientService.get_all_patients(db, skip=skip, limit=limit)

@router.get("/api/patients/{patient_id}", response_model=PatientResponse)
def get_patient_by_id_api(patient_id: str, db: Session = Depends(get_db)):
    """Retrieve details for a specific patient by patient ID."""
    return PatientService.get_patient_by_id(db, patient_id)

@router.put("/api/patients/{patient_id}", response_model=PatientResponse)
def update_patient_api(patient_id: str, req: PatientUpdate, db: Session = Depends(get_db)):
    """Update patient information."""
    return PatientService.update_patient(db, patient_id, req)

@router.delete("/api/patients/{patient_id}")
def delete_patient_api(patient_id: str, db: Session = Depends(get_db)):
    """Delete a patient record."""
    return PatientService.delete_patient(db, patient_id)


# --- Legacy Compatibility Endpoints under /patients (matches legacy main.py) ---

@router.post("/patients")
def create_patient_legacy(patient: PatientCreate, db: Session = Depends(get_db)):
    """Add a patient (Legacy endpoint returning original format)."""
    saved = PatientService.create_patient(db, patient)
    return {
        "message": "Patient data saved successfully",
        "patient": saved.model_dump()
    }

@router.get("/patients")
def get_patients_legacy(db: Session = Depends(get_db)):
    """Get all patients (Legacy endpoint returning original {'patients': [...]} format)."""
    patients = PatientService.get_all_patients(db)
    return {
        "patients": [p.model_dump() for p in patients]
    }

@router.get("/patients/{patient_id}")
def get_patient_legacy(patient_id: str, db: Session = Depends(get_db)):
    """Get patient by ID (Legacy endpoint)."""
    patient = PatientService.get_patient_by_id(db, patient_id)
    return patient.model_dump()
