from typing import Optional, List
from pydantic import BaseModel, ConfigDict

class AudioMetadataResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    audio_id: str
    filename: str
    original_filename: str
    file_size: int
    mime_type: str
    duration_seconds: int
    recorded_at: str
    patient_id: Optional[str] = None
    user_id: Optional[str] = None
    download_url: str

class AudioListResponse(BaseModel):
    total: int
    recordings: List[AudioMetadataResponse]
