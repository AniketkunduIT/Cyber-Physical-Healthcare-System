import json
import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.patient import Patient
from app.schemas.patient import PatientCreate, PatientUpdate, PatientResponse
from app.core.config import settings

class PatientService:
    @staticmethod
    def _sync_legacy_json(db: Session):
        """Keep legacy data.json updated with all patients in the database."""
        try:
            patients = db.query(Patient).all()
            data = {
                "patients": [
                    {
                        "patient_id": p.patient_id,
                        "age": p.age,
                        "weight": p.weight,
                        "bmi": p.bmi if p.bmi is not None else 0.0,
                        "gender": p.gender,
                        "known_disease": p.known_disease or "",
                        "allergies": p.allergies or "",
                        "emergency_type": p.emergency_type
                    }
                    for p in patients
                ]
            }
            settings.LEGACY_DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(settings.LEGACY_DATA_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4)
        except Exception as e:
            print(f"[WARN] Failed to sync data.json: {e}")

    @staticmethod
    def create_patient(db: Session, req: PatientCreate, user_id: Optional[str] = None) -> PatientResponse:
        patient_id = "P" + uuid.uuid4().hex[:8]

        # Calculate placeholder BMI if not supplied (weight / 1.7^2)
        bmi = req.bmi
        if bmi is None and req.weight > 0:
            bmi = round(req.weight / (1.7 * 1.7), 1)

        new_patient = Patient(
            id=str(uuid.uuid4()),
            patient_id=patient_id,
            user_id=user_id,
            age=req.age,
            weight=req.weight,
            bmi=bmi,
            gender=req.gender,
            known_disease=req.known_disease or "",
            allergies=req.allergies or "",
            emergency_type=req.emergency_type
        )
        db.add(new_patient)
        db.commit()
        db.refresh(new_patient)

        # Sync legacy data.json
        PatientService._sync_legacy_json(db)

        return PatientResponse(
            patient_id=new_patient.patient_id,
            age=new_patient.age,
            weight=new_patient.weight,
            bmi=new_patient.bmi,
            gender=new_patient.gender,
            known_disease=new_patient.known_disease,
            allergies=new_patient.allergies,
            emergency_type=new_patient.emergency_type
        )

    @staticmethod
    def get_all_patients(db: Session, skip: int = 0, limit: int = 200) -> List[PatientResponse]:
        patients = db.query(Patient).offset(skip).limit(limit).all()
        return [
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
            for p in patients
        ]

    @staticmethod
    def get_patient_by_id(db: Session, patient_id: str) -> PatientResponse:
        patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
        if not patient:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Patient with ID '{patient_id}' not found"
            )
        return PatientResponse(
            patient_id=patient.patient_id,
            age=patient.age,
            weight=patient.weight,
            bmi=patient.bmi,
            gender=patient.gender,
            known_disease=patient.known_disease or "",
            allergies=patient.allergies or "",
            emergency_type=patient.emergency_type
        )

    @staticmethod
    def update_patient(db: Session, patient_id: str, req: PatientUpdate) -> PatientResponse:
        patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
        if not patient:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Patient with ID '{patient_id}' not found"
            )

        if req.age is not None:
            patient.age = req.age
        if req.weight is not None:
            patient.weight = req.weight
            if req.bmi is None and req.weight > 0:
                patient.bmi = round(req.weight / (1.7 * 1.7), 1)
        if req.bmi is not None:
            patient.bmi = req.bmi
        if req.gender is not None:
            patient.gender = req.gender
        if req.known_disease is not None:
            patient.known_disease = req.known_disease
        if req.allergies is not None:
            patient.allergies = req.allergies
        if req.emergency_type is not None:
            patient.emergency_type = req.emergency_type

        db.commit()
        db.refresh(patient)
        PatientService._sync_legacy_json(db)

        return PatientResponse(
            patient_id=patient.patient_id,
            age=patient.age,
            weight=patient.weight,
            bmi=patient.bmi,
            gender=patient.gender,
            known_disease=patient.known_disease or "",
            allergies=patient.allergies or "",
            emergency_type=patient.emergency_type
        )

    @staticmethod
    def delete_patient(db: Session, patient_id: str) -> dict:
        patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
        if not patient:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Patient with ID '{patient_id}' not found"
            )
        db.delete(patient)
        db.commit()
        PatientService._sync_legacy_json(db)
        return {"message": f"Patient '{patient_id}' deleted successfully."}
