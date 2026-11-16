import uuid
from datetime import datetime, timezone
from typing import Optional, List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.medical_record import MedicalProfile, Prescription
from app.models.audio import AudioRecord
from app.models.patient import Patient
from app.schemas.medical_record import (
    MedicalProfileCreate, MedicalProfileResponse,
    PrescriptionCreate, PrescriptionResponse,
    VoiceNoteResponse
)

class MedicalService:
    @staticmethod
    def get_or_create_profile(db: Session, user_id: str = "user_001") -> MedicalProfile:
        profile = db.query(MedicalProfile).filter(MedicalProfile.user_id == user_id).first()
        if not profile:
            profile = MedicalProfile(
                id=f"mp_{user_id}",
                user_id=user_id,
                known_diseases="",
                allergies=""
            )
            db.add(profile)
            db.commit()
            db.refresh(profile)
        return profile

    @staticmethod
    def get_profile_response(db: Session, user_id: str = "user_001") -> MedicalProfileResponse:
        profile = MedicalService.get_or_create_profile(db, user_id)

        # Retrieve Prescriptions
        prescriptions = db.query(Prescription).filter(
            (Prescription.medical_profile_id == profile.id) |
            (Prescription.user_id == user_id)
        ).order_by(Prescription.uploaded_at.desc()).all()

        # Retrieve Voice Notes / Audio Records
        audio_records = db.query(AudioRecord).filter(
            (AudioRecord.medical_profile_id == profile.id) |
            (AudioRecord.user_id == user_id)
        ).order_by(AudioRecord.recorded_at.desc()).all()

        # Derive BMI
        bmi = None
        if profile.weight_kg and profile.weight_kg > 0:
            bmi = round(profile.weight_kg / (1.7 * 1.7), 1)

        pres_responses = [
            PrescriptionResponse(
                id=p.id,
                fileName=p.file_name,
                fileSizeBytes=p.file_size_bytes,
                doctorName=p.doctor_name,
                prescriptionDate=p.prescription_date,
                medicinesNotes=p.medicines_notes,
                uploadedAt=p.uploaded_at.isoformat(),
                isUploaded=True
            )
            for p in prescriptions
        ]

        voice_responses = [
            VoiceNoteResponse(
                id=a.audio_id,
                durationSeconds=a.duration_seconds,
                recordedAt=a.recorded_at.isoformat()
            )
            for a in audio_records
        ]

        return MedicalProfileResponse(
            age=profile.age,
            weightKg=profile.weight_kg,
            gender=profile.gender,
            knownDiseases=profile.known_diseases or "",
            allergies=profile.allergies or "",
            selectedEmergencyTypeId=profile.selected_emergency_type_id,
            bmi=bmi,
            prescriptions=pres_responses,
            voiceNotes=voice_responses
        )

    @staticmethod
    def save_profile(db: Session, req: MedicalProfileCreate, user_id: str = "user_001") -> MedicalProfileResponse:
        profile = MedicalService.get_or_create_profile(db, user_id)

        profile.age = req.age
        profile.weight_kg = req.weightKg
        profile.gender = req.gender
        profile.known_diseases = req.knownDiseases or ""
        profile.allergies = req.allergies or ""
        profile.selected_emergency_type_id = req.selectedEmergencyTypeId
        profile.updated_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(profile)

        # Also sync or create a Patient record for this user so patient queries find it
        patient = db.query(Patient).filter(Patient.user_id == user_id).first()
        if patient:
            if req.age is not None:
                patient.age = req.age
            if req.weightKg is not None:
                patient.weight = req.weightKg
                patient.bmi = round(req.weightKg / (1.7 * 1.7), 1)
            if req.gender:
                patient.gender = req.gender
            if req.knownDiseases is not None:
                patient.known_disease = req.knownDiseases
            if req.allergies is not None:
                patient.allergies = req.allergies
            if req.selectedEmergencyTypeId:
                patient.emergency_type = req.selectedEmergencyTypeId
            db.commit()

        return MedicalService.get_profile_response(db, user_id)

    @staticmethod
    def save_prescription(db: Session, req: PrescriptionCreate, user_id: str = "user_001") -> PrescriptionResponse:
        profile = MedicalService.get_or_create_profile(db, user_id)
        pres_id = req.id or f"pres_{uuid.uuid4().hex[:12]}"

        existing = db.query(Prescription).filter(Prescription.id == pres_id).first()
        now = datetime.now(timezone.utc)
        if existing:
            existing.file_name = req.fileName
            existing.file_size_bytes = req.fileSizeBytes
            existing.doctor_name = req.doctorName
            existing.prescription_date = req.prescriptionDate
            existing.medicines_notes = req.medicinesNotes
            db.commit()
            db.refresh(existing)
            prescription = existing
        else:
            prescription = Prescription(
                id=pres_id,
                medical_profile_id=profile.id,
                user_id=user_id,
                file_name=req.fileName,
                file_size_bytes=req.fileSizeBytes,
                doctor_name=req.doctorName,
                prescription_date=req.prescriptionDate,
                medicines_notes=req.medicinesNotes,
                uploaded_at=now
            )
            db.add(prescription)
            db.commit()
            db.refresh(prescription)

        return PrescriptionResponse(
            id=prescription.id,
            fileName=prescription.file_name,
            fileSizeBytes=prescription.file_size_bytes,
            doctorName=prescription.doctor_name,
            prescriptionDate=prescription.prescription_date,
            medicinesNotes=prescription.medicines_notes,
            uploadedAt=prescription.uploaded_at.isoformat(),
            isUploaded=True
        )

    @staticmethod
    def delete_prescription(db: Session, prescription_id: str, user_id: Optional[str] = None) -> dict:
        query = db.query(Prescription).filter(Prescription.id == prescription_id)
        if user_id:
            query = query.filter(Prescription.user_id == user_id)
        prescription = query.first()
        if not prescription:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Prescription '{prescription_id}' not found."
            )
        db.delete(prescription)
        db.commit()
        return {"message": f"Prescription '{prescription_id}' deleted successfully."}
