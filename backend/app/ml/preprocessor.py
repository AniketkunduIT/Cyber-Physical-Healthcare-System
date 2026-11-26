"""Feature Preprocessing for XGBoost and SHAP Explainability.

Ensures that incoming patient features strictly adhere to the model's
feature schema, physiological ranges, clinical units, and binary encodings.
Never silently alters or clips patient measurements.
"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set
import numpy as np
import pandas as pd

from app.ml.model_loader import ModelLoader, ModelSchemaError, get_model_loader

# Binary symptom features requiring strict boolean/binary encoding
BINARY_FEATURES: Set[str] = {
    "breathlessness",
    "chest_pain",
    "fever",
    "vomiting",
}

# Physiological reference bounds and units for clinical safety
PHYSIOLOGICAL_BOUNDS: Dict[str, Dict[str, Any]] = {
    "age": {
        "min": 0.0,
        "max": 125.0,
        "unit": "years",
        "description": "Patient age in years"
    },
    "bmi": {
        "min": 10.0,
        "max": 80.0,
        "unit": "kg/m²",
        "description": "Body Mass Index"
    },
    "heart_rate": {
        "min": 25.0,
        "max": 260.0,
        "unit": "bpm",
        "description": "Heart rate in beats per minute"
    },
    "systolic_bp": {
        "min": 50.0,
        "max": 260.0,
        "unit": "mmHg",
        "description": "Systolic blood pressure"
    },
    "diastolic_bp": {
        "min": 30.0,
        "max": 160.0,
        "unit": "mmHg",
        "description": "Diastolic blood pressure"
    },
    "oxygen_saturation": {
        "min": 50.0,
        "max": 100.0,
        "unit": "%",
        "description": "Pulse oximetry oxygen saturation (SpO2 percentage)"
    },
    "temperature_c": {
        "min": 28.0,
        "max": 45.0,
        "unit": "°C",
        "description": "Core body temperature in Celsius"
    },
}


@dataclass
class PreprocessingResult:
    """Holds processed feature DataFrame and transparency metadata."""
    df: pd.DataFrame
    imputed_features: List[str] = field(default_factory=list)
    unrecognized_features: List[str] = field(default_factory=list)
    row_dict: Dict[str, float] = field(default_factory=dict)


class FeaturePreprocessor:
    """Preprocesses and validates patient input features with physiological checks."""

    def __init__(self, loader: Optional[ModelLoader] = None):
        self.loader = loader or get_model_loader()

    def preprocess(
        self,
        raw_features: Dict[str, Any],
        allow_defaults: bool = False,
    ) -> PreprocessingResult:
        """Validates and formats raw patient dictionary into a single-row DataFrame.

        Enforces:
        1. All expected features are accounted for.
        2. Binary features are strictly 0 or 1 (rejects non-binary values).
        3. Physiological vitals fall within biologically viable clinical bounds.
        4. Diastolic BP is strictly lower than Systolic BP.
        5. Tracks all missing features substituted via defaults for transparency.
        6. Identifies any unrecognized keys passed in the request.

        Raises:
            ModelSchemaError: If any feature is missing, non-numeric, or outside valid clinical ranges.
        """
        if not isinstance(raw_features, dict) or not raw_features:
            raise ModelSchemaError("Features must be provided as a non-empty key-value dictionary.")

        # Normalize key names: strip whitespace, lower-case
        normalized_input: Dict[str, Any] = {
            str(k).strip().lower(): v
            for k, v in raw_features.items()
        }

        expected_features = self.loader.get_feature_names()
        defaults = self.loader.get_default_values() if allow_defaults else {}

        # Detect unrecognized/typo features for transparency
        unrecognized_features = [
            k for k in normalized_input.keys()
            if k not in expected_features
        ]

        # Check for missing features
        missing_features: List[str] = []
        imputed_features: List[str] = []
        row_data: Dict[str, float] = {}

        for feat in expected_features:
            is_imputed = False
            val = None

            if feat in normalized_input:
                val = normalized_input[feat]
            elif feat in defaults:
                val = defaults[feat]
                is_imputed = True
                imputed_features.append(feat)
            else:
                missing_features.append(feat)
                continue

            # Strict validation for binary symptoms (breathlessness, chest_pain, fever, vomiting)
            if feat in BINARY_FEATURES:
                if isinstance(val, bool):
                    numeric_val = 1.0 if val else 0.0
                elif isinstance(val, (int, float)):
                    if val in (0, 1, 0.0, 1.0):
                        numeric_val = float(val)
                    else:
                        raise ModelSchemaError(
                            f"Feature '{feat}' must be a binary indicator (0 for absent, 1 for present). "
                            f"Received invalid value: {val!r}."
                        )
                elif isinstance(val, str) and val.strip() in ("0", "1"):
                    numeric_val = float(val.strip())
                else:
                    raise ModelSchemaError(
                        f"Feature '{feat}' must be a binary indicator (0 for absent, 1 for present). "
                        f"Received invalid value: {val!r}."
                    )
                row_data[feat] = numeric_val
                continue

            # Validation for continuous physiological features
            try:
                numeric_val = float(val)
                if np.isnan(numeric_val) or np.isinf(numeric_val):
                    raise ValueError("NaN or Inf value detected")
            except (ValueError, TypeError):
                raise ModelSchemaError(
                    f"Invalid value for feature '{feat}': received {val!r}. Must be a valid numeric measurement."
                )

            # Physiological clinical range validation
            if feat in PHYSIOLOGICAL_BOUNDS:
                bounds = PHYSIOLOGICAL_BOUNDS[feat]
                min_val = bounds["min"]
                max_val = bounds["max"]
                unit = bounds["unit"]

                if numeric_val < min_val or numeric_val > max_val:
                    # Provide helpful diagnostic for temperature unit mistakes (Fahrenheit vs Celsius)
                    if feat == "temperature_c" and numeric_val > max_val:
                        raise ModelSchemaError(
                            f"Temperature value '{numeric_val}' is outside physiological range [{min_val}{unit} - {max_val}{unit}]. "
                            f"If recorded in Fahrenheit, please convert to Celsius before submitting: (°F - 32) * 5/9."
                        )
                    raise ModelSchemaError(
                        f"Physiological value out of bounds for '{feat}': received {numeric_val} {unit}. "
                        f"Clinically valid range is [{min_val} - {max_val} {unit}]."
                    )

            row_data[feat] = numeric_val

        # Blood pressure relational check
        if "systolic_bp" in row_data and "diastolic_bp" in row_data:
            sbp = row_data["systolic_bp"]
            dbp = row_data["diastolic_bp"]
            if dbp >= sbp:
                raise ModelSchemaError(
                    f"Diastolic blood pressure ({dbp:.0f} mmHg) cannot be greater than or equal to "
                    f"systolic blood pressure ({sbp:.0f} mmHg)."
                )

        if missing_features:
            raise ModelSchemaError(
                f"Missing required feature(s): {missing_features}. "
                f"Model requires all 11 features: {expected_features}. "
                f"To permit population defaults for omitted features, set 'allow_defaults': true."
            )

        # Build DataFrame with strictly ordered columns
        df = pd.DataFrame([row_data], columns=expected_features)

        return PreprocessingResult(
            df=df,
            imputed_features=imputed_features,
            unrecognized_features=unrecognized_features,
            row_dict=row_data,
        )


def preprocess_features(
    raw_features: Dict[str, Any],
    allow_defaults: bool = False,
    loader: Optional[ModelLoader] = None
) -> PreprocessingResult:
    """Convenience helper for preprocessing patient features."""
    preprocessor = FeaturePreprocessor(loader=loader)
    return preprocessor.preprocess(raw_features, allow_defaults=allow_defaults)
