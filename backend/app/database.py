import os
import json
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.core.config import settings

connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Dependency that yields a database session and ensures closure."""
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables and seed initial data safely without overwriting."""
    # Import all models to register them on Base.metadata
    from app.models.user import User
    from app.models.patient import Patient
    from app.models.medical_record import MedicalProfile, Prescription
    from app.models.audio import AudioRecord
    from app.models.emergency import EmergencyRequest, Hospital
    from app.core.security import hash_password

    Base.metadata.create_all(bind=engine)

    db: Session = SessionLocal()
    try:
        # 1. Seed Default User if empty
        existing_user = db.query(User).filter(User.username_or_phone == "user_001").first()
        if not existing_user:
            default_user = User(
                id="user_001",
                name="Riya Sharma",
                username_or_phone="user_001",
                email="riya.sharma@example.com",
                hashed_password=hash_password("password123"),
                role="patient"
            )
            db.add(default_user)
            db.commit()

        # 2. Seed / Migrate Patients from data.json if table is empty or missing them
        if settings.LEGACY_DATA_FILE.exists():
            try:
                with open(settings.LEGACY_DATA_FILE, "r", encoding="utf-8") as f:
                    legacy_data = json.load(f)
                    patients_list = legacy_data.get("patients", [])
                    for p in patients_list:
                        pid = p.get("patient_id")
                        if not pid:
                            continue
                        exists = db.query(Patient).filter(Patient.patient_id == pid).first()
                        if not exists:
                            new_patient = Patient(
                                patient_id=pid,
                                user_id="user_001",
                                age=p.get("age", 0),
                                weight=float(p.get("weight", 0.0)),
                                bmi=float(p.get("bmi", 0.0)) if p.get("bmi") is not None else None,
                                gender=p.get("gender", "unknown"),
                                known_disease=p.get("known_disease", ""),
                                allergies=p.get("allergies", ""),
                                emergency_type=p.get("emergency_type", "unspecified")
                            )
                            db.add(new_patient)
                    db.commit()
            except Exception as e:
                print(f"[WARN] Could not seed legacy data.json: {e}")

        # 3. Seed Default Hospitals if empty
        if db.query(Hospital).count() == 0:
            default_hospitals = [
                Hospital(
                    id="h1",
                    name="Manipal Hospital",
                    address="Old Airport Road, Bengaluru",
                    distance_km=1.2,
                    phone="+918041176000",
                    has_emergency_beds=True,
                    latitude=12.9592,
                    longitude=77.6534
                ),
                Hospital(
                    id="h2",
                    name="Fortis Hospital",
                    address="Bannerghatta Road, Bengaluru",
                    distance_km=3.4,
                    phone="+918066214444",
                    has_emergency_beds=True,
                    latitude=12.8931,
                    longitude=77.5976
                ),
                Hospital(
                    id="h3",
                    name="Apollo Hospital",
                    address="Bannerghatta Road, Bengaluru",
                    distance_km=4.8,
                    phone="+918026304050",
                    has_emergency_beds=False,
                    latitude=12.8918,
                    longitude=77.5989
                ),
            ]
            db.add_all(default_hospitals)
            db.commit()

        # 4. Seed a default medical profile for user_001 if empty
        if db.query(MedicalProfile).filter(MedicalProfile.user_id == "user_001").first() is None:
            default_profile = MedicalProfile(
                id="mp_user_001",
                user_id="user_001",
                patient_id="P7f8016c0",
                age=22,
                weight_kg=55.0,
                gender="female",
                known_diseases="none",
                allergies="peanuts",
                selected_emergency_type_id="trauma"
            )
            db.add(default_profile)
            db.commit()

    finally:
        db.close()
