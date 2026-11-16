from app.routers.auth import router as auth_router
from app.routers.patients import router as patients_router
from app.routers.medical_records import router as medical_router
from app.routers.audio import router as audio_router
from app.routers.emergency import router as emergency_router
from app.routers.dashboard import router as dashboard_router

__all__ = [
    "auth_router",
    "patients_router",
    "medical_router",
    "audio_router",
    "emergency_router",
    "dashboard_router"
]
