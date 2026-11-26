"""XGBoost Prediction Module for Cyber-Physical Healthcare System.

Performs forward inference on preprocessed patient features, returning
predicted class, class label, and probability distribution.
"""

from typing import Any, Dict, Optional, Tuple, Union
import numpy as np
import pandas as pd
import xgboost as xgb

from app.ml.model_loader import ModelLoader, get_model_loader


def predict_xgboost(
    X: Union[pd.DataFrame, np.ndarray],
    model: Optional[Any] = None,
    loader: Optional[ModelLoader] = None,
) -> Dict[str, Any]:
    """Runs prediction on patient feature vector.

    Args:
        X: Preprocessed DataFrame or 2D array of patient features.
        model: Pre-loaded model, or None to load via loader.
        loader: ModelLoader instance.

    Returns:
        dict containing:
            - predicted_class_idx: int
            - predicted_class_label: str
            - probabilities: Dict[str, float]
            - raw_prediction: Any
    """
    loader = loader or get_model_loader()
    active_model = model or loader.load_model()
    class_labels = loader.get_class_labels()

    if isinstance(X, pd.DataFrame):
        feature_names = list(X.columns)
        X_mat = X.to_numpy()
    else:
        feature_names = loader.get_feature_names()
        X_mat = np.asarray(X)

    if X_mat.ndim == 1:
        X_mat = X_mat.reshape(1, -1)

    predicted_class_idx: int = 0
    probabilities: Dict[str, float] = {}

    # Case 1: Scikit-learn API (XGBClassifier)
    if hasattr(active_model, "predict_proba"):
        try:
            probs = active_model.predict_proba(X)[0]
            predicted_class_idx = int(np.argmax(probs))
            for idx, p in enumerate(probs):
                label_name = class_labels.get(idx, f"Class {idx}")
                probabilities[label_name] = round(float(p), 4)
        except Exception:
            preds = active_model.predict(X)[0]
            predicted_class_idx = int(preds)
            probabilities = {class_labels.get(predicted_class_idx, f"Class {predicted_class_idx}"): 1.0}

    # Case 2: Raw xgb.Booster
    elif isinstance(active_model, xgb.Booster):
        dmat = xgb.DMatrix(X_mat, feature_names=feature_names)
        raw_preds = active_model.predict(dmat)
        if raw_preds.ndim == 2 and raw_preds.shape[1] > 1:
            # Multi-class probabilities
            probs = raw_preds[0]
            predicted_class_idx = int(np.argmax(probs))
            for idx, p in enumerate(probs):
                label_name = class_labels.get(idx, f"Class {idx}")
                probabilities[label_name] = round(float(p), 4)
        elif raw_preds.ndim == 1:
            # Binary or regression
            val = float(raw_preds[0])
            if 0.0 <= val <= 1.0:
                predicted_class_idx = 1 if val >= 0.5 else 0
                probabilities = {
                    class_labels.get(0, "Class 0"): round(1.0 - val, 4),
                    class_labels.get(1, "Class 1"): round(val, 4),
                }
            else:
                predicted_class_idx = int(round(val))
                probabilities = {class_labels.get(predicted_class_idx, f"Class {predicted_class_idx}"): 1.0}
    else:
        # Fallback for generic scikit-learn models
        preds = active_model.predict(X_mat)
        predicted_class_idx = int(preds[0])
        probabilities = {class_labels.get(predicted_class_idx, f"Class {predicted_class_idx}"): 1.0}

    predicted_label = class_labels.get(predicted_class_idx, f"Class {predicted_class_idx}")

    return {
        "predicted_class_idx": predicted_class_idx,
        "predicted_class_label": predicted_label,
        "probabilities": probabilities,
    }
