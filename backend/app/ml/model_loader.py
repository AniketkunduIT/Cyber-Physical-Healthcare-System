"""Model Loader for XGBoost in Cyber-Physical Healthcare System.

Maintains separation between model loading, schema resolution, and
explanation logic. Allows plug-and-play replacement of the development
model with production models without changing SHAP explainability code.
"""

import json
import logging
import os
import pickle
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union
import xgboost as xgb

from app.core.config import settings

logger = logging.getLogger(__name__)


class ModelSchemaError(ValueError):
    """Raised when the input features do not match the expected model schema."""
    pass


class ModelNotFoundError(FileNotFoundError):
    """Raised when the specified model file cannot be located."""
    pass


class ModelLoader:
    """Manages loading, introspecting, caching, and validating XGBoost models."""

    def __init__(
        self,
        model_path: Optional[Union[str, Path]] = None,
        metadata_path: Optional[Union[str, Path]] = None,
    ):
        self.model_path = Path(model_path or settings.XGBOOST_MODEL_PATH)
        self.metadata_path = Path(metadata_path or settings.MODEL_METADATA_PATH)
        self._cached_model: Optional[Any] = None
        self._cached_metadata: Optional[Dict[str, Any]] = None

    def reload(
        self,
        model_path: Optional[Union[str, Path]] = None,
        metadata_path: Optional[Union[str, Path]] = None,
    ) -> None:
        """Forces reloading the model and metadata from disk, optionally changing paths."""
        if model_path:
            self.model_path = Path(model_path)
        if metadata_path:
            self.metadata_path = Path(metadata_path)
        self._cached_model = None
        self._cached_metadata = None
        logger.info(f"ModelLoader cache cleared. Active model path: {self.model_path}")

    def load_metadata(self) -> Dict[str, Any]:
        """Loads metadata JSON if available, or derives basic metadata dynamically."""
        if self._cached_metadata is not None:
            return self._cached_metadata

        metadata: Dict[str, Any] = {}
        if self.metadata_path.exists():
            try:
                with open(self.metadata_path, "r", encoding="utf-8") as f:
                    metadata = json.load(f)
            except Exception as e:
                logger.warning(f"Failed to read metadata file at {self.metadata_path}: {e}")

        self._cached_metadata = metadata
        return metadata

    def load_model(self) -> Any:
        """Loads and caches the XGBoost model from the configured path."""
        if self._cached_model is not None:
            return self._cached_model

        if not self.model_path.exists():
            # If the dev model is missing, attempt to generate it automatically
            try:
                from app.ml.dev_model_generator import generate_dev_model_if_missing
                generate_dev_model_if_missing()
            except Exception as e:
                logger.error(f"Failed to generate dev model: {e}")

        if not self.model_path.exists():
            raise ModelNotFoundError(
                f"XGBoost model file not found at '{self.model_path}'. "
                "Ensure the trained model is placed in the designated directory or set the XGBOOST_MODEL_PATH environment variable."
            )

        suffix = self.model_path.suffix.lower()
        model: Any = None

        if suffix in (".json", ".ubj", ".bin", ".model"):
            # Prefer XGBClassifier wrapper when applicable for standard scikit-learn API
            try:
                clf = xgb.XGBClassifier()
                clf.load_model(str(self.model_path))
                model = clf
            except Exception as e:
                logger.debug(f"XGBClassifier load_model failed ({e}), falling back to raw xgb.Booster")
                booster = xgb.Booster()
                booster.load_model(str(self.model_path))
                model = booster

        elif suffix in (".pkl", ".pickle"):
            with open(self.model_path, "rb") as f:
                model = pickle.load(f)

        elif suffix == ".joblib":
            import joblib
            model = joblib.load(str(self.model_path))

        else:
            # Fallback attempt
            try:
                clf = xgb.XGBClassifier()
                clf.load_model(str(self.model_path))
                model = clf
            except Exception:
                booster = xgb.Booster()
                booster.load_model(str(self.model_path))
                model = booster

        self._cached_model = model
        logger.info(f"Loaded XGBoost model from '{self.model_path}' successfully.")
        return model

    def get_feature_names(self) -> List[str]:
        """Resolves the expected feature names from metadata or model introspection."""
        metadata = self.load_metadata()
        if metadata and "feature_names" in metadata and metadata["feature_names"]:
            return list(metadata["feature_names"])

        model = self.load_model()
        # Introspect scikit-learn / XGBoost model attributes
        if hasattr(model, "feature_names_in_") and model.feature_names_in_ is not None:
            return list(model.feature_names_in_)

        booster = model.get_booster() if hasattr(model, "get_booster") else model
        if hasattr(booster, "feature_names") and booster.feature_names:
            return list(booster.feature_names)

        raise ModelSchemaError(
            "Unable to determine expected model feature names. "
            "Please provide a companion 'model_metadata.json' with a 'feature_names' array."
        )

    def get_class_labels(self) -> Dict[Union[int, str], str]:
        """Resolves the class index to label name mapping from metadata or model."""
        metadata = self.load_metadata()
        if metadata and "class_labels" in metadata and metadata["class_labels"]:
            # Convert keys to int if numeric
            labels = {}
            for k, v in metadata["class_labels"].items():
                try:
                    labels[int(k)] = str(v)
                except ValueError:
                    labels[k] = str(v)
            return labels

        model = self.load_model()
        if hasattr(model, "classes_") and model.classes_ is not None:
            return {int(idx): str(cls_val) for idx, cls_val in enumerate(model.classes_)}

        # Default fallback for binary/multiclass
        return {0: "Class 0", 1: "Class 1"}

    def get_default_values(self) -> Dict[str, Any]:
        """Returns configured default values for optional/imputed features."""
        metadata = self.load_metadata()
        return metadata.get("default_values", {})

    def validate_input_features(
        self,
        features: Dict[str, Any],
        allow_defaults: bool = False,
    ) -> List[str]:
        """Validates that input features contain all required features expected by the model.

        Raises:
            ModelSchemaError: With explicit details of missing or invalid features.
        """
        expected = self.get_feature_names()
        defaults = self.get_default_values() if allow_defaults else {}

        missing = []
        for feat in expected:
            if feat not in features and feat not in defaults:
                missing.append(feat)

        if missing:
            raise ModelSchemaError(
                f"Missing required feature(s) for model schema: {missing}. "
                f"Expected features: {expected}"
            )

        return expected


# Global default instance
_default_loader: Optional[ModelLoader] = None


def get_model_loader() -> ModelLoader:
    """Returns the shared ModelLoader instance."""
    global _default_loader
    if _default_loader is None:
        _default_loader = ModelLoader()
    return _default_loader
