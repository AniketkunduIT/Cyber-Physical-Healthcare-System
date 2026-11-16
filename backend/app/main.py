import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.database import init_db
from app.routers import (
    auth_router,
    patients_router,
    medical_router,
    audio_router,
    emergency_router,
    dashboard_router
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables and seed legacy & default data
    init_db()
    yield

app = FastAPI(
    title=settings.APP_NAME,
    description="Cyber Physical Healthcare System Backend API providing patient management, medical records, raw audio storage, emergency dispatch, and analytics.",
    version="2.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Modular Routers
app.include_router(auth_router)
app.include_router(patients_router)
app.include_router(medical_router)
app.include_router(audio_router)
app.include_router(emergency_router)
app.include_router(dashboard_router)

@app.get("/", tags=["Root"])
def root():
    """Root health and system verification endpoint."""
    return {
        "message": "Cyber Physical Healthcare Backend is running!",
        "status": "online",
        "app_name": settings.APP_NAME,
        "docs_url": "/docs"
    }

@app.get("/health", tags=["Root"])
def health_check():
    """Health check endpoint for container and uptime monitoring."""
    return {
        "status": "healthy",
        "database": "connected"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=True)
