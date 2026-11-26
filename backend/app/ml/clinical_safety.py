"""Clinical Safety & Emergency Red-Flag Verification.

Ensures that emergency decision-making, clinical red flags, and critical
care escalation operate independently of machine learning and SHAP models.
"""

from typing import Any, Dict, List

EMERGENCY_DISCLAIMER = (
    "Clinical Decision Support Only. Emergency clinical red flags operate independently "
    "of machine learning and SHAP explainability. If any clinical red flags are present, "
    "immediate medical intervention and emergency escalation must proceed regardless of "
    "model predictions or SHAP feature contributions."
)


def evaluate_emergency_red_flags(features: Dict[str, float]) -> Dict[str, Any]:
    """Evaluates clinical emergency red flags independently of machine learning models.

    Args:
        features: Dictionary of patient clinical measurements.

    Returns:
        dict containing:
            - red_flag_triggered: bool
            - red_flags: List[str]
            - clinical_action: str
            - independent_of_ml: bool
    """
    flags: List[str] = []

    spo2 = features.get("oxygen_saturation")
    if spo2 is not None and spo2 < 90.0:
        flags.append(f"Critical Hypoxia: SpO2 {spo2:.1f}% is below 90.0% (Risk of respiratory failure).")

    sbp = features.get("systolic_bp")
    dbp = features.get("diastolic_bp")
    if sbp is not None:
        if sbp >= 180.0:
            flags.append(f"Hypertensive Crisis: Systolic BP {sbp:.0f} mmHg >= 180 mmHg (Stroke/infarction risk).")
        elif sbp < 80.0:
            flags.append(f"Severe Hypotension: Systolic BP {sbp:.0f} mmHg < 80 mmHg (Cardiogenic/septic shock risk).")

    if dbp is not None and dbp >= 120.0:
        flags.append(f"Hypertensive Crisis: Diastolic BP {dbp:.0f} mmHg >= 120 mmHg.")

    hr = features.get("heart_rate")
    if hr is not None:
        if hr > 140.0:
            flags.append(f"Extreme Tachycardia: Heart rate {hr:.0f} bpm > 140 bpm.")
        elif hr < 40.0:
            flags.append(f"Severe Bradycardia: Heart rate {hr:.0f} bpm < 40 bpm.")

    temp = features.get("temperature_c")
    if temp is not None:
        if temp >= 40.5:
            flags.append(f"Hyperpyrexia: Core temperature {temp:.1f}°C >= 40.5°C.")
        elif temp < 34.0:
            flags.append(f"Severe Hypothermia: Core temperature {temp:.1f}°C < 34.0°C.")

    chest_pain = features.get("chest_pain", 0)
    breathlessness = features.get("breathlessness", 0)
    if chest_pain == 1 and breathlessness == 1:
        flags.append("Acute Cardiopulmonary Distress: Concomitant chest pain and breathlessness (Suspected ACS/PE).")

    triggered = len(flags) > 0

    return {
        "red_flag_triggered": triggered,
        "red_flags": flags,
        "clinical_action": (
            "EMERGENCY PROTOCOL REQUIRED: Immediate clinical evaluation and triage escalation needed."
            if triggered
            else "Routine clinical monitoring: No immediate physiological red flags detected."
        ),
        "independent_of_ml": True,
    }
