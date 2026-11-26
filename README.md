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

## SHAP Explainability & Clinical Decision Support

The backend features a modular **SHAP (SHapley Additive exPlanations)** explainability engine using `shap.TreeExplainer` for tree-based XGBoost models.

### Key Capabilities
- **Individual Patient Attributions**: Explains vital sign and symptom contributions towards triage urgency classes (e.g., `Standard`, `Priority`, `Urgent`).
- **Directionality**: Identifies whether each feature moves the risk assessment toward (`positive`) or away from (`negative`) the target class relative to the model baseline.
- **Strict Clinical Safety**: Purely a clinical decision-support capability. Does not override emergency red-flag rules or clinical clinician discretion.
- **Plug-and-Play Model Replacement**: The model loader is completely decoupled from explanation logic. Any trained XGBoost model (`.json`, `.ubj`, `.bin`, `.pkl`, `.joblib`) can be plugged in without changing backend code.

### Endpoints
- `POST /api/shap/explain`: Computes SHAP values and feature direction for a patient.
- `GET /api/shap/model-info`: Retrieves active model metadata, expected feature list, and types.
- `POST /api/shap/reload-model`: Flushes explainer cache and re-reads model files from disk.

### Sample Request (`POST /api/shap/explain`)
```json
{
  "features": {
    "age": 68,
    "bmi": 28.5,
    "heart_rate": 135,
    "systolic_bp": 175,
    "diastolic_bp": 105,
    "oxygen_saturation": 86.0,
    "temperature_c": 39.2,
    "breathlessness": 1,
    "chest_pain": 1,
    "fever": 1,
    "vomiting": 0
  }
}
```

### Sample Response
```json
{
  "status": "success",
  "predicted_class": "Urgent",
  "explanation": [
    {
      "feature": "oxygen_saturation",
      "shap_value": 0.5103,
      "direction": "positive"
    },
    {
      "feature": "breathlessness",
      "shap_value": 0.4974,
      "direction": "positive"
    },
    {
      "feature": "chest_pain",
      "shap_value": 0.4736,
      "direction": "positive"
    },
    {
      "feature": "heart_rate",
      "shap_value": 0.4591,
      "direction": "positive"
    },
    {
      "feature": "systolic_bp",
      "shap_value": 0.3648,
      "direction": "positive"
    },
    {
      "feature": "vomiting",
      "shap_value": -0.0008,
      "direction": "negative"
    }
  ],
  "base_value": 0.0676,
  "target_class": "Urgent",
  "probabilities": {
    "Standard": 0.0081,
    "Priority": 0.0131,
    "Urgent": 0.9788
  },
  "safety_disclaimer": "Clinical Decision Support Only. SHAP values indicate model feature contributions relative to the baseline expected value; they do not represent absolute clinical risk percentages or direct medical causes of symptoms."
}
```

### Model Replacement Procedure
1. Export your trained XGBoost model in JSON format (e.g. `clf.save_model("my_triage_model.json")`).
2. Place the file in `backend/ml_models/` (or update `XGBOOST_MODEL_PATH` in `.env`).
3. Update `backend/ml_models/model_metadata.json` with the model's `feature_names`, `feature_types`, and `class_labels`.
4. Call `POST /api/shap/reload-model` to immediately load the new model into memory.

---

## Running Automated Tests

### Backend Tests (pytest)
```bash
cd backend
python -m pytest tests/ -v
```
*(All 26 test suites verify auth, patient CRUD, audio upload, healing, emergency dispatch, dashboard stats, and SHAP explainability)*

### Frontend Tests (flutter test)
```bash
cd Cyber-Physical-Healthcare-System
flutter test
```
*(All widget tests verify authentication, profile actions, prescription forms, and voice recording sheet)*

---

## License
MIT License
