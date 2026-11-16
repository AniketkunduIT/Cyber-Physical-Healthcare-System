import io
import os
import sys
from pathlib import Path
import pytest
from starlette.testclient import TestClient

# Add backend directory to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.main import app
from app.database import init_db

@pytest.fixture(scope="session", autouse=True)
def setup_database():
    init_db()

@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c

def test_root_endpoint(client):
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert "Cyber Physical Healthcare Backend is running!" in data["message"]

def test_health_endpoint(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "healthy"

def test_auth_login_default_user(client):
    res = client.post("/api/auth/login", json={
        "username_or_phone": "user_001",
        "password": "password123"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["id"] == "user_001"
    assert "token" in data

def test_auth_register_and_me(client):
    username = f"testuser_{os.urandom(4).hex()}"
    res = client.post("/api/auth/register", json={
        "name": "Dr. Sarah Connor",
        "username_or_phone": username,
        "email": f"{username}@healthcare.org",
        "password": "securepassword123"
    })
    assert res.status_code == 201
    data = res.json()
    token = data["token"]
    assert data["name"] == "Dr. Sarah Connor"

    # Test /api/auth/me
    res_me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res_me.status_code == 200
    assert res_me.json()["username_or_phone"] == username

def test_legacy_patients_get_and_seed(client):
    # Verify legacy GET /patients returns the seeded patients from data.json
    res = client.get("/patients")
    assert res.status_code == 200
    data = res.json()
    assert "patients" in data
    assert len(data["patients"]) >= 11
    # Check known patient P7f8016c0
    patient_ids = [p["patient_id"] for p in data["patients"]]
    assert "P7f8016c0" in patient_ids

def test_legacy_patients_post(client):
    res = client.post("/patients", json={
        "age": 35,
        "weight": 70.0,
        "gender": "male",
        "known_disease": "mild asthma",
        "allergies": "dust",
        "emergency_type": "respiratory"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["message"] == "Patient data saved successfully"
    patient = data["patient"]
    assert patient["patient_id"].startswith("P")

    # Verify retrieval
    res_get = client.get(f"/patients/{patient['patient_id']}")
    assert res_get.status_code == 200
    assert res_get.json()["age"] == 35

def test_modular_patients_crud(client):
    # Create
    res = client.post("/api/patients", json={
        "age": 42,
        "weight": 65.0,
        "gender": "female",
        "known_disease": "none",
        "allergies": "latex",
        "emergency_type": "trauma"
    })
    assert res.status_code == 201
    created = res.json()
    pid = created["patient_id"]
    assert created["bmi"] is not None

    # Update
    res_put = client.put(f"/api/patients/{pid}", json={
        "known_disease": "controlled hypertension"
    })
    assert res_put.status_code == 200
    assert res_put.json()["known_disease"] == "controlled hypertension"

    # Delete
    res_del = client.delete(f"/api/patients/{pid}")
    assert res_del.status_code == 200

def test_medical_profile_get_and_save(client):
    # GET profile
    res = client.get("/api/medical/profile?user_id=user_001")
    assert res.status_code == 200
    data = res.json()
    assert "prescriptions" in data
    assert "voiceNotes" in data

    # SAVE profile
    res_save = client.post("/api/medical/profile?user_id=user_001", json={
        "age": 23,
        "weightKg": 56.5,
        "gender": "female",
        "knownDiseases": "seasonal allergies",
        "allergies": "peanuts",
        "selectedEmergencyTypeId": "trauma"
    })
    assert res_save.status_code == 200
    saved = res_save.json()
    assert saved["age"] == 23
    assert saved["weightKg"] == 56.5

def test_prescriptions_add_and_delete(client):
    res = client.post("/api/medical/prescriptions?user_id=user_001", json={
        "fileName": "prescription_amoxicillin.pdf",
        "fileSizeBytes": 245000,
        "doctorName": "Dr. Mehta",
        "prescriptionDate": "16 / 11 / 2026",
        "medicinesNotes": "Amoxicillin 500mg twice daily for 5 days"
    })
    assert res.status_code == 201
    data = res.json()
    assert data["doctorName"] == "Dr. Mehta"
    pres_id = data["id"]

    # Delete prescription
    res_del = client.delete(f"/api/medical/prescriptions/{pres_id}")
    assert res_del.status_code == 200

def test_audio_raw_upload_retrieval_and_delete(client):
    # Prepare dummy raw audio bytes (representing an uncompressed PCM WAV or WebM)
    raw_audio_content = b"RIFF____WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x80>\x00\x00\x00}\x00\x00\x02\x00\x10\x00data" + b"\x00\x01\x02\x03" * 256
    audio_file = io.BytesIO(raw_audio_content)

    # 1. Upload raw audio
    upload_res = client.post(
        "/api/audio/upload",
        files={"file": ("emergency_consultation.wav", audio_file, "audio/wav")},
        data={"duration_seconds": 12, "patient_id": "P7f8016c0"}
    )
    assert upload_res.status_code == 201
    meta = upload_res.json()
    assert meta["duration_seconds"] == 12
    assert meta["patient_id"] == "P7f8016c0"
    assert meta["file_size"] == len(raw_audio_content)
    audio_id = meta["audio_id"]

    # 2. List audio metadata
    list_res = client.get("/api/audio/")
    assert list_res.status_code == 200
    list_data = list_res.json()
    assert list_data["total"] >= 1
    ids = [r["audio_id"] for r in list_data["recordings"]]
    assert audio_id in ids

    # 3. Retrieve raw audio file and verify byte-for-byte integrity
    get_res = client.get(f"/api/audio/{audio_id}")
    assert get_res.status_code == 200
    assert get_res.content == raw_audio_content  # Raw content preserved exactly!
    assert "audio/wav" in get_res.headers.get("content-type", "")

    # 4. Check medical profile includes this audio note
    med_res = client.get("/api/medical/profile?user_id=user_001")
    assert med_res.status_code == 200
    profile_voice_notes = [v["id"] for v in med_res.json()["voiceNotes"]]
    assert audio_id in profile_voice_notes

    # 5. Delete audio file
    del_res = client.delete(f"/api/audio/{audio_id}")
    assert del_res.status_code == 200

    # Verify 404 after deletion
    get_again = client.get(f"/api/audio/{audio_id}")
    assert get_again.status_code == 404

def test_corrupt_audio_healed_to_mp3(client):
    # Upload deliberately corrupt audio bytes (broken headers)
    corrupted_audio_data = b"RIFFBROKENHEADER\x00\x00data" + (b"\x12\x34\x56\x78" * 500)
    audio_file = io.BytesIO(corrupted_audio_data)

    res = client.post(
        "/api/audio/upload",
        files={"file": ("corrupt_recording.wav", audio_file, "audio/wav")},
        data={"duration_seconds": 4, "patient_id": "P7f8016c0"}
    )
    assert res.status_code == 201
    meta = res.json()
    # Verified: healed to .mp3 format
    assert meta["filename"].endswith(".mp3")
    assert meta["mime_type"] == "audio/mpeg"

    # Verify retrieval
    get_res = client.get(f"/api/audio/{meta['audio_id']}")
    assert get_res.status_code == 200
    assert "audio/mpeg" in get_res.headers.get("content-type", "")

    # Cleanup
    client.delete(f"/api/audio/{meta['audio_id']}")

def test_store_as_mp3_flag(client):
    pcm_data = b"\x00\x01\x02\x03" * 1000
    audio_file = io.BytesIO(pcm_data)

    res = client.post(
        "/api/audio/upload",
        files={"file": ("clean_stream.pcm", audio_file, "audio/wav")},
        data={"duration_seconds": 5, "store_as_mp3": "true"}
    )
    assert res.status_code == 201
    meta = res.json()
    assert meta["filename"].endswith(".mp3")
    assert meta["mime_type"] == "audio/mpeg"

    client.delete(f"/api/audio/{meta['audio_id']}")

def test_emergency_ambulance_request(client):
    res = client.post("/api/emergency/request-ambulance", json={
        "latitude": 12.9352,
        "longitude": 77.6146,
        "emergencyTypeId": "cardiac"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["driverName"] == "Rakesh Sharma"
    assert data["etaMinutes"] == 7
    assert len(data["equipment"]) >= 1

def test_emergency_nearby_hospitals(client):
    res = client.get("/api/emergency/hospitals")
    assert res.status_code == 200
    hospitals = res.json()
    assert len(hospitals) >= 3
    hospital_names = [h["name"] for h in hospitals]
    assert "Manipal Hospital" in hospital_names
    assert "Fortis Hospital" in hospital_names

def test_healthcare_dashboard_stats(client):
    res = client.get("/api/dashboard/stats")
    assert res.status_code == 200
    stats = res.json()
    assert stats["total_patients"] >= 11
    assert "total_emergency_requests" in stats
    assert "emergencies_by_type" in stats
    assert len(stats["recent_patients"]) >= 1
