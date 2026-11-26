import os
from pathlib import Path
from dotenv import load_dotenv

# Base directory: points to C:\Cyber\backend
BASE_DIR = Path(__file__).resolve().parent.parent.parent
load_dotenv(BASE_DIR / ".env")

class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "Cyber Physical Healthcare System")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() in ("true", "1")
    HOST: str = os.getenv("HOST", "127.0.0.1")
    PORT: int = int(os.getenv("PORT", 8000))

    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "cyber_healthcare_super_secret_jwt_key_change_in_production")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 1440))

    # Database: resolve relative sqlite URL against BASE_DIR
    _raw_db = os.getenv("DATABASE_URL", f"sqlite:///{BASE_DIR / 'cyber_healthcare.db'}")
    if _raw_db.startswith("sqlite:///./"):
        DATABASE_URL: str = f"sqlite:///{BASE_DIR / _raw_db.replace('sqlite:///./', '')}"
    else:
        DATABASE_URL: str = _raw_db

    # Uploads
    UPLOAD_AUDIO_DIR: Path = BASE_DIR / os.getenv("UPLOAD_AUDIO_DIR", "uploads/audio")
    UPLOAD_PRESCRIPTION_DIR: Path = BASE_DIR / os.getenv("UPLOAD_PRESCRIPTION_DIR", "uploads/prescriptions")
    MAX_AUDIO_SIZE_MB: int = int(os.getenv("MAX_AUDIO_SIZE_MB", 50))

    # Legacy data file path for migration & synchronization
    _candidate_data = BASE_DIR / "data.json"
    if not _candidate_data.exists():
        _candidate_data = BASE_DIR / "Cyber-Physical-Healthcare-System" / "backend" / "data.json"
    LEGACY_DATA_FILE: Path = _candidate_data

    # CORS
    ALLOWED_ORIGINS: list[str] = [
        origin.strip()
        for origin in os.getenv("ALLOWED_ORIGINS", "*").split(",")
    ]

    # Machine Learning & SHAP Explainability
    ML_MODELS_DIR: Path = BASE_DIR / os.getenv("ML_MODELS_DIR", "ml_models")
    XGBOOST_MODEL_PATH: Path = BASE_DIR / os.getenv("XGBOOST_MODEL_PATH", "ml_models/xgboost_triage_model.json")
    MODEL_METADATA_PATH: Path = BASE_DIR / os.getenv("MODEL_METADATA_PATH", "ml_models/model_metadata.json")

settings = Settings()

# Ensure directories exist
settings.UPLOAD_AUDIO_DIR.mkdir(parents=True, exist_ok=True)
settings.UPLOAD_PRESCRIPTION_DIR.mkdir(parents=True, exist_ok=True)
settings.ML_MODELS_DIR.mkdir(parents=True, exist_ok=True)
