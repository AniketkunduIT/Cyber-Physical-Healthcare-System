"""Machine Learning and SHAP Explainability Package.

Contains model loading, preprocessing, XGBoost inference, and
SHAP TreeExplainer integration for clinical decision support.
"""

from app.ml.model_loader import (
    ModelLoader,
    ModelSchemaError,
    ModelNotFoundError,
    get_model_loader,
)
from app.ml.preprocessor import FeaturePreprocessor, preprocess_features
from app.ml.xgboost_predict import predict_xgboost
from app.ml.shap_explainer import (
    ShapExplainer,
    get_shap_explainer,
    explain_patient,
    CLINICAL_SAFETY_DISCLAIMER,
)
from app.ml.clinical_safety import (
    evaluate_emergency_red_flags,
    EMERGENCY_DISCLAIMER,
)
from app.ml.dev_model_generator import generate_dev_model_if_missing

__all__ = [
    "ModelLoader",
    "ModelSchemaError",
    "ModelNotFoundError",
    "get_model_loader",
    "FeaturePreprocessor",
    "preprocess_features",
    "predict_xgboost",
    "ShapExplainer",
    "get_shap_explainer",
    "explain_patient",
    "CLINICAL_SAFETY_DISCLAIMER",
    "evaluate_emergency_red_flags",
    "EMERGENCY_DISCLAIMER",
    "generate_dev_model_if_missing",
]
