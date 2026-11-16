from typing import Optional, List
from fastapi import APIRouter, Depends, UploadFile, File, Form, Query, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.audio import AudioMetadataResponse, AudioListResponse
from app.services.audio_service import AudioService
from app.core.security import get_current_user_token

router = APIRouter(prefix="/api/audio", tags=["Audio Recording & Storage"])

@router.post("/upload", response_model=AudioMetadataResponse, status_code=status.HTTP_201_CREATED)
async def upload_audio(
    file: UploadFile = File(..., description="Raw audio file to upload (e.g. WebM, WAV, MP3, M4A)"),
    duration_seconds: int = Form(0, ge=0, description="Duration of recording in seconds"),
    patient_id: Optional[str] = Form(None, description="Optional associated patient ID"),
    user_id: Optional[str] = Form(None, description="Optional associated user ID"),
    store_as_mp3: bool = Form(False, description="Optional: force store as standard MP3 file"),
    token_data: Optional[dict] = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """
    Upload a raw audio recording.
    The audio is saved directly to disk. If the audio has corrupted headers or if store_as_mp3
    is specified, it is automatically converted and stored as a clean, standard MP3 file.
    """
    effective_user_id = user_id or (token_data.get("sub") if token_data else "user_001")
    return await AudioService.upload_audio_file(
        db=db,
        file=file,
        duration_seconds=duration_seconds,
        patient_id=patient_id,
        user_id=effective_user_id,
        store_as_mp3=store_as_mp3
    )

@router.get("/", response_model=AudioListResponse)
def list_audio_recordings(
    patient_id: Optional[str] = Query(None, description="Filter by patient ID"),
    user_id: Optional[str] = Query(None, description="Filter by user ID"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db)
):
    """List metadata for all uploaded audio recordings."""
    records = AudioService.list_audio_records(
        db=db,
        patient_id=patient_id,
        user_id=user_id,
        skip=skip,
        limit=limit
    )
    return AudioListResponse(total=len(records), recordings=records)

@router.get("/{audio_id}")
def get_audio_file(audio_id: str, db: Session = Depends(get_db)):
    """
    Retrieve and stream the original raw audio file in its original format.
    Supports playback and downloading.
    """
    file_path, mime_type, original_filename = AudioService.get_audio_file_path(db, audio_id)
    return FileResponse(
        path=str(file_path),
        media_type=mime_type,
        filename=original_filename,
        headers={
            "Accept-Ranges": "bytes",
            "Content-Disposition": f'inline; filename="{original_filename}"'
        }
    )

@router.delete("/{audio_id}")
def delete_audio(
    audio_id: str,
    token_data: Optional[dict] = Depends(get_current_user_token),
    db: Session = Depends(get_db)
):
    """Delete an audio recording and its underlying raw file from disk."""
    return AudioService.delete_audio_record(db, audio_id)
