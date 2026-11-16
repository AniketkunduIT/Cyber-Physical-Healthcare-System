from app.schemas.user import UserRegisterRequest, UserLoginRequest, PasswordResetRequest, UserResponse
from app.schemas.patient import PatientCreate, PatientUpdate, PatientResponse
from app.schemas.medical_record import (
    MedicalProfileCreate, MedicalProfileResponse,
    PrescriptionCreate, PrescriptionResponse,
    VoiceNoteResponse
)
from app.schemas.audio import AudioMetadataResponse, AudioListResponse
from app.schemas.emergency import AmbulanceRequest, AmbulanceResponse, HospitalResponse
from app.schemas.dashboard import DashboardStatsResponse

__all__ = [
    "UserRegisterRequest", "UserLoginRequest", "PasswordResetRequest", "UserResponse",
    "PatientCreate", "PatientUpdate", "PatientResponse",
    "MedicalProfileCreate", "MedicalProfileResponse",
    "PrescriptionCreate", "PrescriptionResponse",
    "VoiceNoteResponse",
    "AudioMetadataResponse", "AudioListResponse",
    "AmbulanceRequest", "AmbulanceResponse", "HospitalResponse",
    "DashboardStatsResponse"
]
