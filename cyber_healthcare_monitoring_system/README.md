# Cyber Physical Healthcare System (MediRescue)

A full-stack emergency healthcare and medical assistance platform featuring a **Flutter** mobile/web frontend and a **Python FastAPI** backend with SQLite database, real-time audio recording & raw file storage, medical record management, and emergency ambulance dispatch.

---

## Project Structure

```text
Cyber/
├── backend/                                # Python FastAPI Backend
│   ├── app/                                # Modular application package
│   │   ├── core/                           # Configuration & Security (JWT, Bcrypt)
│   │   ├── models/                         # SQLAlchemy database models
│   │   ├── schemas/                        # Pydantic v2 validation models
│   │   ├── services/                       # Business logic services
│   │   ├── routers/                        # REST API endpoints
│   │   ├── database.py                     # Database connection & auto-seeding
│   │   └── main.py                         # FastAPI app entrypoint
│   ├── tests/                              # Pytest test suite (15 tests)
│   ├── uploads/                            # Uploaded files
│   │   ├── audio/                          # Dedicated raw audio storage
│   │   └── prescriptions/                  # Uploaded prescription files
│   ├── data.json                           # Pre-seeded legacy patient records
│   ├── requirements.txt                    # Backend dependencies
│   ├── run_server.py                       # Standalone server startup script
│   └── .env.example                        # Environment configuration template
│
└── Cyber-Physical-Healthcare-System/       # Flutter Frontend Application
    ├── lib/                                # Flutter source code
    │   ├── models/                         # Data models
    │   ├── providers/                      # State management (Provider)
    │   ├── routes/                         # Navigation router
    │   ├── screens/                        # UI screens (Auth, Home, Medical Profile, Dispatch)
    │   ├── services/                       # API repositories & Audio recorder helper
    │   └── widgets/                        # Reusable UI widgets & Voice recording sheet
    ├── test/                               # Flutter widget tests
    └── pubspec.yaml                        # Flutter package configuration
```

---

## Quick Start Guide

### 1. Backend Setup (FastAPI)

#### Prerequisites
- Python 3.10+ installed

#### Steps
```bash
# 1. Navigate to backend directory
cd backend

# 2. Create and activate a virtual environment
python -m venv venv

# Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# macOS / Linux:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. (Optional) Create .env from template
copy .env.example .env     # Windows
# or: cp .env.example .env # macOS/Linux

# 5. Run the FastAPI server
python run_server.py
```

The backend starts on `http://127.0.0.1:8000`.
- **Interactive Swagger API Docs**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **Database**: Automatically initialized and seeded on first run (`cyber_healthcare.db`).

---

### 2. Frontend Setup (Flutter)

#### Prerequisites
- Flutter SDK 3.19+ installed

#### Steps
```bash
# 1. Navigate to Flutter project directory
cd Cyber-Physical-Healthcare-System

# 2. Fetch packages
flutter pub get

# 3. Run the application
# On Chrome (Web):
flutter run -d chrome

# On Windows (Desktop):
flutter run -d windows

# On Android Emulator / Connected Device:
flutter run
```

> **Note for Android Studio & Emulators**:  
> The app automatically detects Android and connects to `http://10.0.2.2:8000` (the host PC address for the Android emulator). Cleartext traffic is enabled in `AndroidManifest.xml`.

---

## Default Login Credentials

A seeded test account is pre-configured:

| Field | Value |
|---|---|
| **Username / Phone** | `user_001` |
| **Password** | `password123` |
| **Full Name** | Riya Sharma |
| **Role** | Patient |

You can also click **"Sign up"** on the login screen to register any new account.

---

## Audio Recording & Raw File Storage

- **Recording**: Real microphone audio is captured in uncompressed WAV or MP3 format using the native `record` library.
- **Upload**: Binary multipart POST to `/api/audio/upload`.
- **Storage**: Raw audio files are saved directly to `backend/uploads/audio/` with unique timestamped filenames (`rec_<uuid>_<timestamp>.mp3`).
- **Healing**: If uploaded audio has corrupted headers, the backend automatically converts and heals it into a standard `.mp3` file using `lameenc`.
- **Playback & Download**: Streamed directly via `/api/audio/{audio_id}`.

---

## Running Automated Tests

### Backend Tests (pytest)
```bash
cd backend
python -m pytest tests/test_backend.py -v
```
*(All 15 test suites verify auth, patient CRUD, audio upload, healing, emergency dispatch, and stats)*

### Frontend Tests (flutter test)
```bash
cd Cyber-Physical-Healthcare-System
flutter test
```
*(All widget tests verify authentication, profile actions, prescription forms, and voice recording sheet)*

---

## License
MIT License
