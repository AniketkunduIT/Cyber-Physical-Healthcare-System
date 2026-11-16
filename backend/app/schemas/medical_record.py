from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class VoiceNoteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    durationSeconds: int
    recordedAt: str

class PrescriptionCreate(BaseModel):
    id: Optional[str] = None
    fileName: str = Field(..., min_length=1)
    fileSizeBytes: int = Field(default=0, ge=0)
    doctorName: str = Field(default="")
    prescriptionDate: str = Field(default="")
    medicinesNotes: str = Field(default="")

class PrescriptionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    fileName: str
    fileSizeBytes: int
    doctorName: str
    prescriptionDate: str
    medicinesNotes: str
    uploadedAt: str
    isUploaded: bool = True

class MedicalProfileCreate(BaseModel):
    age: Optional[int] = Field(None, ge=0, le=130)
    weightKg: Optional[float] = Field(None, gt=0)
    gender: Optional[str] = None
    knownDiseases: Optional[str] = ""
    allergies: Optional[str] = ""
    selectedEmergencyTypeId: Optional[str] = None

class MedicalProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    age: Optional[int] = None
    weightKg: Optional[float] = None
    gender: Optional[str] = None
    knownDiseases: str = ""
    allergies: str = ""
    selectedEmergencyTypeId: Optional[str] = None
    bmi: Optional[float] = None
    prescriptions: List[PrescriptionResponse] = []
    voiceNotes: List[VoiceNoteResponse] = []
