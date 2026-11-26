"""Comprehensive test suite for SHAP Explainability & Model Integration."""

import os
import sys
from pathlib import Path
import pytest
from starlette.testclient import TestClient

# Add backend directory to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.main import app
from app.ml.model_loader import get_model_loader, ModelSchemaError
from app.ml.shap_explainer import get_shap_explainer, CLINICAL_SAFETY_DISCLAIMER
import numpy as np
import xgboost as xgb

client = TestClient(app)


def test_model_loader_and_metadata():
    """Verifies that the model loader successfully retrieves model, features, and classes."""
    loader = get_model_loader()
    model = loader.load_model()
    assert model is not None

    feature_names = loader.get_feature_names()
    assert isinstance(feature_names, list)
    assert len(feature_names) >= 10
    assert "heart_rate" in feature_names
    assert "oxygen_saturation" in feature_names
    assert "chest_pain" in feature_names

    class_labels = loader.get_class_labels()
    assert len(class_labels) >= 2
    assert any("Urgent" in v for v in class_labels.values())


def test_shap_explain_valid_patient_urgent():
    """Tests POST /api/shap/explain on a patient with critical emergency indicators."""
    payload = {
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

    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["status"] == "success"
    assert data["predicted_class"] == "Urgent"
    assert isinstance(data["explanation"], list)
    assert len(data["explanation"]) == len(payload["features"])

    # Verify structure of each explanation entry
    for item in data["explanation"]:
        assert "feature" in item
        assert "shap_value" in item
        assert "direction" in item
        assert item["direction"] in ("positive", "negative", "neutral")
        if item["shap_value"] > 0:
            assert item["direction"] == "positive"
        elif item["shap_value"] < 0:
            assert item["direction"] == "negative"
        else:
            assert item["direction"] == "neutral"

    # Verify highest impact features are sorted first
    shap_magnitudes = [abs(item["shap_value"]) for item in data["explanation"]]
    assert shap_magnitudes == sorted(shap_magnitudes, reverse=True)

    # Verify probabilities and base value
    assert "probabilities" in data
    assert isinstance(data["probabilities"], dict)
    assert "Urgent" in data["probabilities"]
    assert data["probabilities"]["Urgent"] > 0.5

    assert data["base_value"] is not None
    assert "safety_disclaimer" in data
    assert data["safety_disclaimer"] == CLINICAL_SAFETY_DISCLAIMER


def test_shap_explain_valid_patient_standard():
    """Tests POST /api/shap/explain on a stable patient with routine baseline vitals."""
    payload = {
        "features": {
            "age": 28,
            "bmi": 22.0,
            "heart_rate": 72,
            "systolic_bp": 118,
            "diastolic_bp": 78,
            "oxygen_saturation": 99.0,
            "temperature_c": 36.8,
            "breathlessness": 0,
            "chest_pain": 0,
            "fever": 0,
            "vomiting": 0
        }
    }

    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["status"] == "success"
    assert data["predicted_class"] == "Standard"
    assert len(data["explanation"]) > 0
    assert data["probabilities"]["Standard"] > 0.5


def test_shap_explain_target_class_selection():
    """Tests explicitly targeting a specific class (e.g. Priority or Urgent)."""
    payload = {
        "features": {
            "age": 45,
            "bmi": 25.0,
            "heart_rate": 90,
            "systolic_bp": 130,
            "diastolic_bp": 85,
            "oxygen_saturation": 96.0,
            "temperature_c": 38.5,
            "breathlessness": 0,
            "chest_pain": 0,
            "fever": 1,
            "vomiting": 1
        },
        "target_class": "Priority"
    }

    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 200, response.text
    data = response.json()

    assert data["status"] == "success"
    assert data["target_class"] == "Priority"
    assert len(data["explanation"]) > 0


def test_shap_explain_missing_features_error():
    """Tests that missing mandatory features produce a 400 Bad Request with schema guidance."""
    incomplete_payload = {
        "features": {
            "age": 40,
            "heart_rate": 80
            # missing oxygen_saturation, chest_pain, etc.
        },
        "allow_defaults": False
    }

    response = client.post("/api/shap/explain", json=incomplete_payload)
    assert response.status_code == 400
    err = response.json()
    assert "detail" in err
    assert "Missing required feature" in str(err["detail"])


def test_shap_explain_allow_defaults():
    """Tests that allow_defaults=True substitutes median defaults for omitted features."""
    partial_payload = {
        "features": {
            "heart_rate": 130,
            "oxygen_saturation": 88.0,
            "breathlessness": 1,
            "chest_pain": 1
        },
        "allow_defaults": True
    }

    response = client.post("/api/shap/explain", json=partial_payload)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["status"] == "success"
    assert len(data["explanation"]) >= 10


def test_shap_explain_invalid_non_numeric():
    """Tests that non-numeric feature values trigger a clean 400 error."""
    invalid_payload = {
        "features": {
            "age": "forty_five",
            "heart_rate": 80,
            "bmi": 23.0,
            "systolic_bp": 120,
            "diastolic_bp": 80,
            "oxygen_saturation": 98.0,
            "temperature_c": 37.0,
            "breathlessness": 0,
            "chest_pain": 0,
            "fever": 0,
            "vomiting": 0
        }
    }

    response = client.post("/api/shap/explain", json=invalid_payload)
    assert response.status_code == 400
    err = response.json()
    assert "Invalid value for feature 'age'" in str(err["detail"])


def test_shap_model_info_endpoint():
    """Tests GET /api/shap/model-info returns schema metadata and replacement instructions."""
    response = client.get("/api/shap/model-info")
    assert response.status_code == 200
    data = response.json()

    assert data["status"] == "success"
    assert "model_path" in data
    assert "feature_names" in data
    assert "class_labels" in data
    assert "replacement_instructions" in data
    assert "XGBOOST_MODEL_PATH" in data["replacement_instructions"]


def test_shap_reload_model_endpoint():
    """Tests POST /api/shap/reload-model flushes explainer cache and re-validates model."""
    response = client.post("/api/shap/reload-model")
    assert response.status_code == 200
    data = response.json()

    assert data["status"] == "success"
    assert "reloaded successfully" in data["message"]


def test_shap_explainer_accepts_custom_model_instance():
    """Verifies that ShapExplainer accepts any arbitrary compatible trained XGBoost model."""
    from app.ml.shap_explainer import ShapExplainer

    # Train a minimal 2-class binary model
    X_train = np.array([
        [20, 70, 98],
        [25, 75, 99],
        [70, 130, 85],
        [80, 140, 82],
    ], dtype=float)
    y_train = np.array([0, 0, 1, 1], dtype=int)

    custom_model = xgb.XGBClassifier(n_estimators=5, max_depth=2, random_state=42)
    custom_model.fit(X_train, y_train)

    explainer = ShapExplainer(model=custom_model)
    # Explaining with custom model works as an independent unit
    assert explainer.model == custom_model
    assert explainer.explainer is not None


def test_shap_rejects_invalid_binary_symptoms():
    """Verifies that non-binary values for symptoms (breathlessness, chest_pain, etc.) are rejected."""
    payload = {
        "features": {
            "age": 45,
            "bmi": 24.0,
            "heart_rate": 80,
            "systolic_bp": 120,
            "diastolic_bp": 80,
            "oxygen_saturation": 98.0,
            "temperature_c": 37.0,
            "breathlessness": 2,  # Invalid: non-binary
            "chest_pain": 0,
            "fever": 0,
            "vomiting": 0
        }
    }
    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 400
    assert "must be a binary indicator" in response.text


def test_shap_rejects_out_of_bounds_physiological_values():
    """Verifies that impossible physiological measurements (e.g. Fahrenheit temp) are rejected."""
    # Test temperature in Fahrenheit
    f_payload = {
        "features": {
            "age": 45,
            "bmi": 24.0,
            "heart_rate": 80,
            "systolic_bp": 120,
            "diastolic_bp": 80,
            "oxygen_saturation": 98.0,
            "temperature_c": 102.5,  # Fahrenheit accidentally sent to Celsius field
            "breathlessness": 0,
            "chest_pain": 0,
            "fever": 1,
            "vomiting": 0
        }
    }
    res_f = client.post("/api/shap/explain", json=f_payload)
    assert res_f.status_code == 400
    assert "Fahrenheit" in res_f.text

    # Test SpO2 > 100%
    spo2_payload = dict(f_payload)
    spo2_payload["features"] = dict(f_payload["features"])
    spo2_payload["features"]["temperature_c"] = 37.5
    spo2_payload["features"]["oxygen_saturation"] = 115.0
    res_spo2 = client.post("/api/shap/explain", json=spo2_payload)
    assert res_spo2.status_code == 400
    assert "oxygen_saturation" in res_spo2.text


def test_shap_rejects_diastolic_greater_than_systolic():
    """Verifies that invalid blood pressure relationships (diastolic >= systolic) are caught."""
    payload = {
        "features": {
            "age": 50,
            "bmi": 26.0,
            "heart_rate": 85,
            "systolic_bp": 110,
            "diastolic_bp": 125,  # Diastolic > Systolic
            "oxygen_saturation": 97.0,
            "temperature_c": 37.0,
            "breathlessness": 0,
            "chest_pain": 0,
            "fever": 0,
            "vomiting": 0
        }
    }
    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 400
    assert "Diastolic blood pressure" in response.text


def test_shap_explain_margin_and_scale_transparency():
    """Verifies that output scale is explicit and prediction_margin matches base_val + sum(shap)."""
    payload = {
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
    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert data["output_scale"] == "raw_margin"
    assert data["prediction_margin"] is not None
    shap_sum = sum(item["shap_value"] for item in data["explanation"])
    expected_margin = round(data["base_value"] + shap_sum, 4)
    assert abs(data["prediction_margin"] - expected_margin) < 1e-3


def test_shap_explain_imputed_features_transparency():
    """Verifies that missing features populated by defaults are explicitly reported in response."""
    partial_payload = {
        "features": {
            "heart_rate": 120,
            "oxygen_saturation": 89.0,
            "breathlessness": 1,
            "chest_pain": 1
        },
        "allow_defaults": True
    }
    response = client.post("/api/shap/explain", json=partial_payload)
    assert response.status_code == 200
    data = response.json()

    assert "imputed_features" in data
    assert isinstance(data["imputed_features"], list)
    assert "age" in data["imputed_features"]
    assert "systolic_bp" in data["imputed_features"]
    assert len(data["imputed_features"]) == 7  # 11 total - 4 provided = 7 defaulted


def test_shap_explain_emergency_red_flags_independent_trigger():
    """Verifies that critical clinical red flags are independently evaluated and flagged."""
    critical_payload = {
        "features": {
            "age": 70,
            "bmi": 27.0,
            "heart_rate": 150,  # Extreme tachycardia > 140
            "systolic_bp": 190,  # Hypertensive crisis >= 180
            "diastolic_bp": 115,
            "oxygen_saturation": 84.0,  # Critical hypoxia < 90
            "temperature_c": 38.0,
            "breathlessness": 1,  # Acute dual distress
            "chest_pain": 1,
            "fever": 1,
            "vomiting": 0
        }
    }
    response = client.post("/api/shap/explain", json=critical_payload)
    assert response.status_code == 200
    data = response.json()

    assert "emergency_safety" in data
    safety = data["emergency_safety"]
    assert safety["red_flag_triggered"] is True
    assert safety["independent_of_ml"] is True
    assert len(safety["red_flags"]) >= 3


def test_shap_rejects_invalid_target_class():
    """Verifies that out-of-range target class requests are rejected with a 400 error."""
    payload = {
        "features": {
            "age": 45,
            "bmi": 24.0,
            "heart_rate": 80,
            "systolic_bp": 120,
            "diastolic_bp": 80,
            "oxygen_saturation": 98.0,
            "temperature_c": 37.0,
            "breathlessness": 0,
            "chest_pain": 0,
            "fever": 0,
            "vomiting": 0
        },
        "target_class": 99  # Invalid class index
    }
    response = client.post("/api/shap/explain", json=payload)
    assert response.status_code == 400
    assert "out of bounds" in response.text


def test_existing_endpoints_remain_operational():
    """Ensures SHAP integration did not disturb any existing healthcare system APIs."""
    # Health check
    res_health = client.get("/health")
    assert res_health.status_code == 200

    # Hospitals list
    res_hosp = client.get("/api/emergency/hospitals")
    assert res_hosp.status_code == 200

    # Dashboard stats
    res_dash = client.get("/api/dashboard/stats")
    assert res_dash.status_code == 200

    # Patient records
    res_patients = client.get("/api/patients")
    assert res_patients.status_code == 200
