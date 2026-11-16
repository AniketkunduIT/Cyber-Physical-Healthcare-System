import os
import re
import uuid
import time
import wave
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import UploadFile, HTTPException, status
from app.models.audio import AudioRecord
from app.schemas.audio import AudioMetadataResponse
from app.core.config import settings

ALLOWED_EXTENSIONS = {".webm", ".wav", ".mp3", ".m4a", ".ogg", ".aac", ".flac", ".weba", ".pcm", ".raw"}
ALLOWED_MIME_PREFIXES = ("audio/", "video/webm", "application/octet-stream")

class AudioService:
    @staticmethod
    def _sanitize_filename(filename: str) -> str:
        """Sanitize filename to prevent directory traversal and remove unsafe chars."""
        clean = Path(filename).name
        clean = re.sub(r"[^\w\.-]", "_", clean)
        return clean

    @staticmethod
    def _convert_pcm_to_mp3(pcm_data: bytes, sample_rate: int = 16000, channels: int = 1, bit_rate: int = 128) -> bytes:
        """Encode raw PCM 16-bit audio bytes to standard MP3."""
        try:
            import lameenc
            encoder = lameenc.Encoder()
            encoder.set_bit_rate(bit_rate)
            encoder.set_in_sample_rate(sample_rate)
            encoder.set_channels(channels)
            encoder.set_quality(2)
            mp3_data = encoder.encode(pcm_data) + encoder.flush()
            return bytes(mp3_data)
        except Exception as e:
            print(f"[WARN] lameenc MP3 encoding failed: {e}")
            return pcm_data

    @staticmethod
    def _check_and_heal_audio(
        target_path: Path,
        ext: str,
        force_mp3: bool = False
    ) -> tuple[Path, str, str, int]:
        """
        Validates the audio file. If the file is corrupt or force_mp3 is requested,
        converts the audio payload to a clean, standard MP3 file.
        Returns: (final_path, final_filename, mime_type, file_size)
        """
        is_corrupt = False
        sample_rate = 16000
        channels = 1
        pcm_bytes = b""

        # 1. WAV verification
        if ext == ".wav":
            try:
                with wave.open(str(target_path), "rb") as wf:
                    channels = wf.getnchannels()
                    sample_rate = wf.getframerate()
                    frames = wf.getnframes()
                    if frames <= 0 or sample_rate <= 0:
                        is_corrupt = True
                    else:
                        pcm_bytes = wf.readframes(frames)
            except Exception:
                is_corrupt = True

        # 2. If corrupt or force_mp3 requested, convert to standard MP3
        if (is_corrupt or force_mp3) and ext in (".wav", ".pcm", ".raw", ".bin"):
            try:
                # If we couldn't extract PCM via wave.open, read file directly
                if not pcm_bytes:
                    with open(target_path, "rb") as f:
                        raw = f.read()
                        if len(raw) > 44 and raw[:4] == b"RIFF":
                            pcm_bytes = raw[44:]
                        else:
                            pcm_bytes = raw

                if pcm_bytes:
                    mp3_bytes = AudioService._convert_pcm_to_mp3(
                        pcm_bytes,
                        sample_rate=sample_rate if sample_rate > 0 else 16000,
                        channels=channels if channels in (1, 2) else 1
                    )
                    mp3_filename = target_path.stem + ".mp3"
                    mp3_path = target_path.parent / mp3_filename
                    with open(mp3_path, "wb") as f_out:
                        f_out.write(mp3_bytes)

                    # Remove the corrupt/raw file if different
                    if target_path != mp3_path and target_path.exists():
                        target_path.unlink()

                    return mp3_path, mp3_filename, "audio/mpeg", len(mp3_bytes)
            except Exception as e:
                print(f"[WARN] Failed to heal audio to MP3: {e}")

        file_size = target_path.stat().st_size if target_path.exists() else 0
        return target_path, target_path.name, f"audio/{ext.lstrip('.')}", file_size

    @staticmethod
    async def upload_audio_file(
        db: Session,
        file: UploadFile,
        duration_seconds: int = 0,
        patient_id: Optional[str] = None,
        user_id: Optional[str] = None,
        store_as_mp3: bool = False
    ) -> AudioMetadataResponse:
        original_name = file.filename or "recording.webm"
        sanitized_original = AudioService._sanitize_filename(original_name)
        ext = Path(sanitized_original).suffix.lower()

        # Deduce extension if missing
        if not ext:
            if file.content_type and "wav" in file.content_type:
                ext = ".wav"
            elif file.content_type and "mp3" in file.content_type:
                ext = ".mp3"
            elif file.content_type and "m4a" in file.content_type:
                ext = ".m4a"
            elif file.content_type and "ogg" in file.content_type:
                ext = ".ogg"
            else:
                ext = ".webm"

        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported audio format '{ext}'. Allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
            )

        unique_id = uuid.uuid4().hex
        timestamp = int(time.time())
        stored_filename = f"rec_{unique_id}_{timestamp}{ext}"
        target_path = settings.UPLOAD_AUDIO_DIR / stored_filename

        max_bytes = settings.MAX_AUDIO_SIZE_MB * 1024 * 1024
        total_size = 0

        try:
            with open(target_path, "wb") as out_file:
                while chunk := await file.read(1024 * 64):
                    total_size += len(chunk)
                    if total_size > max_bytes:
                        out_file.close()
                        if target_path.exists():
                            target_path.unlink()
                        raise HTTPException(
                            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                            detail=f"Audio file exceeds maximum allowed size of {settings.MAX_AUDIO_SIZE_MB}MB."
                        )
                    out_file.write(chunk)
        except HTTPException:
            raise
        except Exception as e:
            if target_path.exists():
                target_path.unlink()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to save raw audio file: {str(e)}"
            )

        # Inspect integrity: if corrupt or store_as_mp3 requested, convert to valid MP3
        final_path, final_filename, mime_type, final_size = AudioService._check_and_heal_audio(
            target_path=target_path,
            ext=ext,
            force_mp3=store_as_mp3
        )

        audio_id = f"aud_{unique_id[:12]}"
        now = datetime.now(timezone.utc)

        audio_record = AudioRecord(
            audio_id=audio_id,
            user_id=user_id,
            patient_id=patient_id,
            filename=final_filename,
            original_filename=sanitized_original,
            file_path=str(final_path.resolve()),
            mime_type=mime_type,
            file_size=final_size,
            duration_seconds=duration_seconds,
            recorded_at=now,
            created_at=now
        )
        db.add(audio_record)
        db.commit()
        db.refresh(audio_record)

        return AudioMetadataResponse(
            audio_id=audio_record.audio_id,
            filename=audio_record.filename,
            original_filename=audio_record.original_filename,
            file_size=audio_record.file_size,
            mime_type=audio_record.mime_type,
            duration_seconds=audio_record.duration_seconds,
            recorded_at=audio_record.recorded_at.isoformat(),
            patient_id=audio_record.patient_id,
            user_id=audio_record.user_id,
            download_url=f"/api/audio/{audio_record.audio_id}"
        )

    @staticmethod
    def get_audio_record(db: Session, audio_id: str) -> AudioRecord:
        record = db.query(AudioRecord).filter(AudioRecord.audio_id == audio_id).first()
        if not record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Audio recording '{audio_id}' not found."
            )
        return record

    @staticmethod
    def get_audio_file_path(db: Session, audio_id: str) -> tuple[Path, str, str]:
        record = AudioService.get_audio_record(db, audio_id)
        path = Path(record.file_path)
        if not path.is_absolute():
            path = settings.BASE_DIR / path

        try:
            path.resolve().relative_to(settings.UPLOAD_AUDIO_DIR.resolve())
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Security violation: Invalid audio file location."
            )

        if not path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Audio file not found on disk."
            )

        return path, record.mime_type, record.original_filename

    @staticmethod
    def list_audio_records(
        db: Session,
        patient_id: Optional[str] = None,
        user_id: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[AudioMetadataResponse]:
        query = db.query(AudioRecord)
        if patient_id:
            query = query.filter(AudioRecord.patient_id == patient_id)
        if user_id:
            query = query.filter(AudioRecord.user_id == user_id)

        records = query.order_by(AudioRecord.recorded_at.desc()).offset(skip).limit(limit).all()

        return [
            AudioMetadataResponse(
                audio_id=r.audio_id,
                filename=r.filename,
                original_filename=r.original_filename,
                file_size=r.file_size,
                mime_type=r.mime_type,
                duration_seconds=r.duration_seconds,
                recorded_at=r.recorded_at.isoformat(),
                patient_id=r.patient_id,
                user_id=r.user_id,
                download_url=f"/api/audio/{r.audio_id}"
            )
            for r in records
        ]

    @staticmethod
    def delete_audio_record(db: Session, audio_id: str) -> dict:
        record = AudioService.get_audio_record(db, audio_id)
        path = Path(record.file_path)
        if not path.is_absolute():
            path = settings.BASE_DIR / path

        if path.exists():
            try:
                path.unlink()
            except Exception as e:
                print(f"[WARN] Error deleting audio file {path}: {e}")

        db.delete(record)
        db.commit()
        return {"message": f"Audio recording '{audio_id}' successfully deleted."}
