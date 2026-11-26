"""FastAPI Router for SHAP Explainability & Clinical Decision Support.

Exposes endpoints for computing Shapley value explanations, inspecting active
model metadata, and reloading models dynamically without restarting the server.
"""

import logging
from typing import Any, Dict
from fastapi import APIRouter, HTTPException, status

from app.ml.model_loader import ModelSchemaError, ModelNotFoundError, get_model_loader
from app.ml.shap_explainer import get_shap_explainer
from app.schemas.shap import ShapExplainRequest, ShapExplainResponse, ModelInfoResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/shap", tags=["SHAP Explainability"])

REPLACEMENT_INSTRUCTIONS = (
    "To replace the development XGBoost model with your production trained model:\n"
    "1. Save your trained XGBoost model in JSON or UBJ format (e.g. 'my_model.json').\n"
    "2. Place the file in 'backend/ml_models/' or configure XGBOOST_MODEL_PATH in .env.\n"
    "3. Update or generate 'model_metadata.json' detailing 'feature_names', 'feature_types', and 'class_labels'.\n"
    "4. Call POST /api/shap/reload-model to activate the new model without restarting the service."
)


@router.post(
    "/explain",
    response_model=ShapExplainResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate SHAP explanation for patient clinical features"
)
def explain_prediction(payload: ShapExplainRequest) -> Dict[str, Any]:
    """Computes SHAP feature attributions and directionality for patient features.

    - **features**: Key-value pairs for patient vitals/symptoms (e.g., heart_rate, SpO2).
    - **target_class**: Optional specific class label or index to explain (e.g., 'Urgent').
    - **allow_defaults**: When true, missing non-critical features use population median defaults.
    """
    try:
        explainer = get_shap_explainer()
        explanation = explainer.explain(
            raw_features=payload.features,
            target_class=payload.target_class,
            allow_defaults=bool(payload.allow_defaults),
        )
        return explanation

    except ModelSchemaError as e:
        logger.warning(f"SHAP explanation schema mismatch: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "ModelSchemaMismatch",
                "message": str(e),
                "hint": "Call GET /api/shap/model-info to view required model features and types."
            }
        )

    except ModelNotFoundError as e:
        logger.error(f"XGBoost model file missing: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "ModelUnavailable",
                "message": str(e),
            }
        )

    except Exception as e:
        logger.error(f"Unexpected error in SHAP computation: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while calculating SHAP explanation values."
        )


@router.get(
    "/model-info",
    response_model=ModelInfoResponse,
    status_code=status.HTTP_200_OK,
    summary="Get active model metadata and feature schema"
)
def get_model_info() -> Dict[str, Any]:
    """Returns active model schema, expected features, class labels, and replacement instructions."""
    try:
        loader = get_model_loader()
        meta = loader.load_metadata()
        feature_names = loader.get_feature_names()
        class_labels = {str(k): str(v) for k, v in loader.get_class_labels().items()}

        return {
            "status": "success",
            "model_path": str(loader.model_path),
            "model_type": meta.get("model_type", "xgboost"),
            "feature_names": feature_names,
            "feature_types": meta.get("feature_types"),
            "class_labels": class_labels,
            "default_values": meta.get("default_values"),
            "is_dev_model": bool(meta.get("is_dev_model", False)),
            "replacement_instructions": REPLACEMENT_INSTRUCTIONS,
        }
    except Exception as e:
        logger.error(f"Failed to retrieve model info: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to retrieve model information: {e}"
        )


@router.post(
    "/reload-model",
    status_code=status.HTTP_200_OK,
    summary="Reload model and explainer cache dynamically"
)
def reload_model() -> Dict[str, Any]:
    """Clears in-memory model and TreeExplainer caches so changes on disk take immediate effect."""
    try:
        loader = get_model_loader()
        loader.reload()
        explainer = get_shap_explainer()
        explainer.clear_cache()
        # Verify model reloads successfully
        loader.load_model()
        return {
            "status": "success",
            "message": "Model and SHAP explainer cache reloaded successfully.",
            "active_model_path": str(loader.model_path),
            "features_count": len(loader.get_feature_names()),
        }
    except Exception as e:
        logger.error(f"Failed to reload model: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reload model: {e}"
        )
