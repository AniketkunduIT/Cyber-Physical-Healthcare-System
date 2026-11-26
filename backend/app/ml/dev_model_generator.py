"""Development & Testing XGBoost Model Generator for Healthcare Triage.

This module creates a deterministic reference XGBoost triage classifier
used for development, testing, and SHAP explainability verification until
the actual production-trained model is supplied by the data science team.

NOTE: This temporary model is for development/test purposes only and
must never be used for autonomous clinical diagnosis in production.
"""

import json
from pathlib import Path
from typing import Tuple, Dict, Any
import numpy as np
import pandas as pd
import xgboost as xgb

from app.core.config import settings

FEATURE_NAMES = [
    "age",
    "bmi",
    "heart_rate",
    "systolic_bp",
    "diastolic_bp",
    "oxygen_saturation",
    "temperature_c",
    "breathlessness",
    "chest_pain",
    "fever",
    "vomiting",
]

FEATURE_TYPES = {
    "age": "int",
    "bmi": "float",
    "heart_rate": "int",
    "systolic_bp": "int",
    "diastolic_bp": "int",
    "oxygen_saturation": "float",
    "temperature_c": "float",
    "breathlessness": "int",
    "chest_pain": "int",
    "fever": "int",
    "vomiting": "int",
}

CLASS_LABELS = {
    "0": "Standard",
    "1": "Priority",
    "2": "Urgent",
}

DEFAULT_VALUES = {
    "age": 40,
    "bmi": 23.5,
    "heart_rate": 75,
    "systolic_bp": 120,
    "diastolic_bp": 80,
    "oxygen_saturation": 98.0,
    "temperature_c": 37.0,
    "breathlessness": 0,
    "chest_pain": 0,
    "fever": 0,
    "vomiting": 0,
}


def generate_synthetic_triage_data(n_samples: int = 600, random_seed: int = 42) -> Tuple[pd.DataFrame, np.ndarray]:
    """Generates a synthetic patient cohort with realistic clinical triage distributions."""
    rng = np.random.default_rng(random_seed)

    age = rng.integers(18, 85, size=n_samples)
    bmi = np.round(rng.normal(25.0, 4.5, size=n_samples).clip(16.0, 45.0), 1)
    heart_rate = rng.integers(55, 150, size=n_samples)
    systolic_bp = rng.integers(90, 190, size=n_samples)
    diastolic_bp = (systolic_bp * 0.65 + rng.normal(0, 5, size=n_samples)).clip(55, 120).astype(int)
    oxygen_saturation = np.round(rng.normal(97.0, 3.0, size=n_samples).clip(78.0, 100.0), 1)
    temperature_c = np.round(rng.normal(37.0, 0.8, size=n_samples).clip(35.5, 41.0), 1)

    breathlessness = rng.binomial(1, 0.25, size=n_samples)
    chest_pain = rng.binomial(1, 0.20, size=n_samples)
    fever = (temperature_c >= 38.0).astype(int)
    vomiting = rng.binomial(1, 0.15, size=n_samples)

    df = pd.DataFrame({
        "age": age,
        "bmi": bmi,
        "heart_rate": heart_rate,
        "systolic_bp": systolic_bp,
        "diastolic_bp": diastolic_bp,
        "oxygen_saturation": oxygen_saturation,
        "temperature_c": temperature_c,
        "breathlessness": breathlessness,
        "chest_pain": chest_pain,
        "fever": fever,
        "vomiting": vomiting,
    })

    # Rule-informed clinical triage assignment:
    # Class 2 (Urgent): Severe hypoxia (<90% SpO2), or chest pain + breathlessness, or severe hypertension + tachycardia
    # Class 1 (Priority): Moderate fever/vomiting/tachycardia or moderate hypoxia (90-93% SpO2)
    # Class 0 (Standard): Stable vitals, absence of critical signs
    urgency_scores = (
        (oxygen_saturation < 90.0) * 3.5 +
        (oxygen_saturation < 94.0) * 1.5 +
        (chest_pain == 1) * 2.5 +
        (breathlessness == 1) * 2.0 +
        (heart_rate > 120) * 1.5 +
        (systolic_bp > 165) * 1.5 +
        (fever == 1) * 1.0 +
        (vomiting == 1) * 0.8 +
        (age > 65) * 0.5
    )

    y = np.zeros(n_samples, dtype=int)
    y[urgency_scores >= 3.0] = 2  # Urgent
    y[(urgency_scores >= 1.5) & (urgency_scores < 3.0)] = 1  # Priority
    y[urgency_scores < 1.5] = 0  # Standard

    return df, y


def train_and_save_dev_model(
    model_path: Path = settings.XGBOOST_MODEL_PATH,
    metadata_path: Path = settings.MODEL_METADATA_PATH,
    force: bool = False
) -> Dict[str, Any]:
    """Trains and exports the development XGBoost model and its associated metadata JSON."""
    model_path = Path(model_path)
    metadata_path = Path(metadata_path)

    if model_path.exists() and metadata_path.exists() and not force:
        with open(metadata_path, "r", encoding="utf-8") as f:
            return json.load(f)

    model_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.parent.mkdir(parents=True, exist_ok=True)

    X, y = generate_synthetic_triage_data()

    # Train a standard multi-class XGBClassifier
    clf = xgb.XGBClassifier(
        n_estimators=35,
        max_depth=4,
        learning_rate=0.1,
        objective="multi:softprob",
        num_class=3,
        random_state=42,
        eval_metric="mlogloss",
    )
    clf.fit(X, y)

    # Save model in standard XGBoost JSON format
    clf.save_model(str(model_path))

    metadata = {
        "model_type": "xgboost_classifier",
        "model_version": "1.0.0-dev",
        "description": "Development / Reference XGBoost triage model for SHAP explainability verification. Replace with production trained model.",
        "feature_names": FEATURE_NAMES,
        "feature_types": FEATURE_TYPES,
        "class_labels": CLASS_LABELS,
        "default_values": DEFAULT_VALUES,
        "objective": "multi:softprob",
        "num_classes": 3,
        "is_dev_model": True,
    }

    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=4)

    return metadata


def generate_dev_model_if_missing() -> Dict[str, Any]:
    """Generates the dev model only if no existing model and metadata exist."""
    return train_and_save_dev_model(force=False)


if __name__ == "__main__":
    meta = train_and_save_dev_model(force=True)
    print(f"Successfully generated development XGBoost model at: {settings.XGBOOST_MODEL_PATH}")
    print(f"Metadata exported to: {settings.MODEL_METADATA_PATH}")
    print("Features:", meta["feature_names"])
