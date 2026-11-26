"""Pydantic schemas for SHAP explainability requests and responses."""

from typing import Any, Dict, List, Literal, Optional, Union
from pydantic import BaseModel, Field, ConfigDict


class FeatureExplanationItem(BaseModel):
    """Individual feature contribution to the model's prediction."""
    feature: str = Field(..., description="Name of the patient feature or clinical vital sign")
    shap_value: float = Field(..., description="SHAP attribution value relative to the base expected value")
    direction: Literal["positive", "negative", "neutral"] = Field(
        ...,
        description="'positive' indicates movement toward target class; 'negative' indicates movement away"
    )


class ShapExplainRequest(BaseModel):
    """Request payload containing patient clinical features."""
    features: Dict[str, Any] = Field(
        ...,
        description="Key-value dictionary of patient features (e.g., vitals, symptoms)",
        examples=[
            {
                "age": 45,
                "bmi": 26.5,
                "heart_rate": 115,
                "systolic_bp": 150,
                "diastolic_bp": 95,
                "oxygen_saturation": 89.0,
                "temperature_c": 38.8,
                "breathlessness": 1,
                "chest_pain": 1,
                "fever": 1,
                "vomiting": 0
            }
        ]
    )
    target_class: Optional[Union[str, int]] = Field(
        None,
        description="Optional class name or index to explain. Defaults to the model's top predicted class."
    )
    allow_defaults: Optional[bool] = Field(
        False,
        description="If True, missing optional features will use pre-configured population median defaults."
    )


class ShapExplainResponse(BaseModel):
    """Structured response conforming to the project specification."""
    model_config = ConfigDict(from_attributes=True)

    status: str = Field("success", description="Request execution status")
    predicted_class: str = Field(..., description="Model predicted class label (e.g. 'Urgent')")
    explanation: List[FeatureExplanationItem] = Field(
        ...,
        description="Ordered list of feature contributions ranked by absolute SHAP impact"
    )
    base_value: Optional[float] = Field(None, description="Expected value (baseline) of the model output in raw margin space")
    target_class: Optional[str] = Field(None, description="The specific class explained by these SHAP values")
    output_scale: Optional[str] = Field("raw_margin", description="Mathematical output space of SHAP values ('raw_margin' / log-odds)")
    prediction_margin: Optional[float] = Field(None, description="Sum of base_value and SHAP attributions (raw logit before softmax)")
    probabilities: Optional[Dict[str, float]] = Field(None, description="Model output class probabilities (softmax transformed)")
    imputed_features: Optional[List[str]] = Field(default_factory=list, description="List of omitted features that used population defaults")
    unrecognized_features: Optional[List[str]] = Field(default_factory=list, description="List of extra or misspelled keys passed in request")
    emergency_safety: Optional[Dict[str, Any]] = Field(None, description="Independent clinical red-flag evaluation")
    safety_disclaimer: Optional[str] = Field(
        None,
        description="Clinical safety guidance for decision-support use"
    )


class ModelInfoResponse(BaseModel):
    """Metadata detailing the active model schema and replacement instructions."""
    model_config = ConfigDict(from_attributes=True)

    status: str = "success"
    model_path: str
    model_type: str
    feature_names: List[str]
    feature_types: Optional[Dict[str, str]] = None
    class_labels: Dict[str, str]
    default_values: Optional[Dict[str, Any]] = None
    is_dev_model: bool = False
    replacement_instructions: str
