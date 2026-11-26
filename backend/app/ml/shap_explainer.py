"""SHAP Explainability Module for Cyber-Physical Healthcare System.

Implements TreeExplainer-based Shapley value computation for XGBoost models,
providing patient-level feature attributions, directionality, and multiclass
support for clinical decision-support.
"""

import logging
from typing import Any, Dict, List, Optional, Union
import numpy as np
import pandas as pd
import shap

from app.ml.model_loader import ModelLoader, ModelSchemaError, get_model_loader
from app.ml.preprocessor import FeaturePreprocessor
from app.ml.xgboost_predict import predict_xgboost
from app.ml.clinical_safety import evaluate_emergency_red_flags

logger = logging.getLogger(__name__)

CLINICAL_SAFETY_DISCLAIMER = (
    "Clinical Decision Support Only. SHAP values indicate model feature contributions "
    "relative to the baseline expected value; they do not represent absolute clinical risk "
    "percentages or direct medical causes of symptoms."
)


class ShapExplainer:
    """Computes SHAP explanations for XGBoost patient risk predictions."""

    def __init__(
        self,
        model: Optional[Any] = None,
        loader: Optional[ModelLoader] = None,
    ):
        self.loader = loader or get_model_loader()
        self._model = model
        self._explainer: Optional[shap.TreeExplainer] = None
        self._preprocessor = FeaturePreprocessor(loader=self.loader)

    @property
    def model(self) -> Any:
        """Returns the loaded model."""
        if self._model is None:
            self._model = self.loader.load_model()
        return self._model

    @property
    def explainer(self) -> shap.TreeExplainer:
        """Returns the cached TreeExplainer instance, creating it if needed."""
        if self._explainer is None:
            logger.info("Initializing shap.TreeExplainer with XGBoost model...")
            self._explainer = shap.TreeExplainer(self.model)
        return self._explainer

    def clear_cache(self) -> None:
        """Clears the cached explainer and model instances."""
        self._explainer = None
        self._model = None

    def explain(
        self,
        raw_features: Dict[str, Any],
        target_class: Optional[Union[str, int]] = None,
        allow_defaults: bool = False,
    ) -> Dict[str, Any]:
        """Calculates SHAP feature contributions for a given patient.

        Args:
            raw_features: Dictionary of patient features (e.g. vital signs, symptoms).
            target_class: Optional target class label or index to explain. If None,
                          explains the model's top predicted class.
            allow_defaults: Whether missing features should be filled with defaults.

        Returns:
            Structured dictionary matching the API specification:
            {
                "status": "success",
                "predicted_class": "Urgent",
                "explanation": [
                    {"feature": "breathlessness", "shap_value": 0.65, "direction": "positive"},
                    ...
                ],
                "base_value": 0.12,
                "target_class": "Urgent",
                "probabilities": {"Standard": 0.05, "Priority": 0.15, "Urgent": 0.80},
                "safety_disclaimer": "..."
            }
        """
        # 1. Preprocess features to guarantee schema, ordering, and valid numeric types
        prep_result = self._preprocessor.preprocess(raw_features, allow_defaults=allow_defaults)
        df_sample = prep_result.df
        feature_names = list(df_sample.columns)

        # 2. Run prediction to determine predicted class and probabilities
        pred_result = predict_xgboost(df_sample, model=self.model, loader=self.loader)
        predicted_idx = pred_result["predicted_class_idx"]
        predicted_label = pred_result["predicted_class_label"]
        probabilities = pred_result["probabilities"]
        class_labels = self.loader.get_class_labels()

        # 3. Resolve target class index and label
        target_idx: int = predicted_idx
        target_label: str = predicted_label

        if target_class is not None:
            if isinstance(target_class, int):
                if target_class not in class_labels and (target_class < 0 or target_class >= len(class_labels)):
                    raise ModelSchemaError(
                        f"Target class index {target_class} is out of bounds for model with {len(class_labels)} classes. "
                        f"Valid class indices: {list(class_labels.keys())}"
                    )
                target_idx = target_class
                target_label = class_labels.get(target_idx, f"Class {target_idx}")
            elif isinstance(target_class, str):
                # Search by label name (case-insensitive)
                matched = False
                for idx, lbl in class_labels.items():
                    if str(lbl).lower() == str(target_class).strip().lower():
                        target_idx = int(idx)
                        target_label = str(lbl)
                        matched = True
                        break
                if not matched:
                    # Try parsing as string integer
                    try:
                        int_candidate = int(target_class)
                        if int_candidate not in class_labels and (int_candidate < 0 or int_candidate >= len(class_labels)):
                            raise ValueError()
                        target_idx = int_candidate
                        target_label = class_labels.get(target_idx, f"Class {target_idx}")
                    except ValueError:
                        raise ModelSchemaError(
                            f"Unknown target_class '{target_class}'. Available classes: {list(class_labels.values())}"
                        )

        # 4. Compute SHAP values via TreeExplainer
        explainer = self.explainer
        explanation_obj = explainer(df_sample)
        shap_values_raw = explanation_obj.values
        base_values_raw = getattr(explanation_obj, "base_values", None)

        # 5. Extract values for the target class across different SHAP output shapes
        extracted_shap: np.ndarray
        base_val: Optional[float] = None

        # Case A: 3D shape (n_samples, n_features, n_classes) - standard in modern SHAP multiclass
        if shap_values_raw.ndim == 3:
            n_samples, n_feat, n_classes = shap_values_raw.shape
            if target_idx >= n_classes:
                raise ModelSchemaError(
                    f"Target class index {target_idx} exceeds model output classes ({n_classes})."
                )
            extracted_shap = shap_values_raw[0, :, target_idx]
            if base_values_raw is not None:
                if base_values_raw.ndim == 2:
                    base_val = float(base_values_raw[0, target_idx])
                elif base_values_raw.ndim == 1:
                    base_val = float(base_values_raw[target_idx])

        # Case B: 2D shape (n_samples, n_features) - binary classification or single output
        elif shap_values_raw.ndim == 2:
            extracted_shap = shap_values_raw[0, :]
            # For binary classification, class 0 is negative direction of class 1 margin
            if target_idx == 0 and len(class_labels) == 2:
                extracted_shap = -extracted_shap
            if base_values_raw is not None:
                if isinstance(base_values_raw, (np.ndarray, list)):
                    base_val = float(base_values_raw[0])
                else:
                    base_val = float(base_values_raw)

        # Case C: List of 2D arrays (legacy SHAP format)
        elif isinstance(shap_values_raw, list):
            if target_idx >= len(shap_values_raw):
                raise ModelSchemaError(f"Target class index {target_idx} exceeds SHAP output list length.")
            extracted_shap = np.asarray(shap_values_raw[target_idx])[0, :]

        else:
            raise RuntimeError(f"Unexpected SHAP values shape: {shap_values_raw.shape}")

        if base_val is not None:
            base_val = round(float(base_val), 4)

        # Compute raw margin for local accuracy verification (base_val + sum(shap))
        pred_margin: Optional[float] = None
        if base_val is not None:
            pred_margin = round(base_val + float(np.sum(extracted_shap)), 4)

        # 6. Build feature explanation items with direction and rounded impact
        explanations: List[Dict[str, Any]] = []
        for feat_name, sv in zip(feature_names, extracted_shap):
            val_float = round(float(sv), 4)
            if val_float > 0.0:
                direction = "positive"
            elif val_float < 0.0:
                direction = "negative"
            else:
                direction = "neutral"

            explanations.append({
                "feature": feat_name,
                "shap_value": val_float,
                "direction": direction,
            })

        # 7. Sort by absolute SHAP impact (descending) so highest contributors are first
        explanations.sort(key=lambda x: abs(x["shap_value"]), reverse=True)

        # 8. Independent Clinical Red-Flag Evaluation
        emergency_safety = evaluate_emergency_red_flags(prep_result.row_dict)

        return {
            "status": "success",
            "predicted_class": predicted_label,
            "explanation": explanations,
            "base_value": base_val,
            "target_class": target_label,
            "output_scale": "raw_margin",
            "prediction_margin": pred_margin,
            "probabilities": probabilities,
            "imputed_features": prep_result.imputed_features,
            "unrecognized_features": prep_result.unrecognized_features,
            "emergency_safety": emergency_safety,
            "safety_disclaimer": CLINICAL_SAFETY_DISCLAIMER,
        }


# Global default explainer instance
_default_explainer: Optional[ShapExplainer] = None


def get_shap_explainer() -> ShapExplainer:
    """Returns the shared ShapExplainer instance."""
    global _default_explainer
    if _default_explainer is None:
        _default_explainer = ShapExplainer()
    return _default_explainer


def explain_patient(
    features: Dict[str, Any],
    target_class: Optional[Union[str, int]] = None,
    allow_defaults: bool = False,
) -> Dict[str, Any]:
    """Convenience functional helper to explain patient features."""
    return get_shap_explainer().explain(
        raw_features=features,
        target_class=target_class,
        allow_defaults=allow_defaults,
    )
