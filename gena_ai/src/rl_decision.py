"""
NabhKrishi RL Decision-Support Module (PPO V3).

Provides deterministic inference using the trained PPO V3 Stable-Baselines3 policy
(nabhkrishi_ppo_v3.zip).

IMPORTANT:
- PPO V3 is a decision-support model, NOT a disease classifier and NOT a treatment prescription engine.
- Observation space: Box(0.0, 1.0, (60,), float32)
- Action space: Discrete(6)
- Exact action mapping:
    0 = Monitor
    1 = Preventive Management
    2 = Irrigation / Nutrient Review
    3 = Disease Management Review
    4 = Recheck
    5 = Ask NabhKrishi Chatbot
"""

import os
import sys
import logging
from pathlib import Path
from typing import Dict, Any, Optional, Union, List
import numpy as np

logger = logging.getLogger("nabhkrishi.rl")

# ============================================================
# 1. Paths and Constants
# ============================================================

SRC_DIR = Path(__file__).resolve().parent
GENA_AI_DIR = SRC_DIR.parent
MODELS_DIR = GENA_AI_DIR / "models"
DEFAULT_PPO_PATH = MODELS_DIR / "nabhkrishi_ppo_v3.zip"
YIELD_MODEL_PATH = MODELS_DIR / "yield_model.pkl"
YIELD_PREP_PATH = MODELS_DIR / "yield_preprocessor.pkl"
YIELD_FEATS_PATH = MODELS_DIR / "yield_features.pkl"

# Exact 15 classes from Swin-T vision model
DISEASES: List[str] = [
    "aphid",
    "black rust",
    "blast",
    "brown rust",
    "common root rot",
    "fusarium head blight",
    "healthy",
    "leaf blight",
    "mildew",
    "mite",
    "septoria",
    "smut",
    "stem fly",
    "tan spot",
    "yellow rust",
]

# 6 crop growth stages
STAGES: List[str] = [
    "Establishment",
    "Early Vegetative",
    "Tillering",
    "Stem/Booting",
    "Heading/Flowering",
    "Grain Filling",
]

# Exact 6 actions from trained PPO V3 policy
ACTION_MAP: Dict[int, str] = {
    0: "Monitor",
    1: "Preventive Management",
    2: "Irrigation / Nutrient Review",
    3: "Disease Management Review",
    4: "Recheck",
    5: "Ask NabhKrishi Chatbot",
}

ACTION_DESCRIPTIONS_EN: Dict[int, str] = {
    0: "Continue monitoring your crop under standard management.",
    1: "Preventive crop-management review is recommended.",
    2: "Irrigation or nutrient management needs review.",
    3: "Disease-management review is recommended.",
    4: "Please capture another clear image for rechecking.",
    5: "Let's discuss this with NabhKrishi AI.",
}

ACTION_DESCRIPTIONS_HI: Dict[int, str] = {
    0: "अपनी फसल की सामान्य रूप से नियमित निगरानी जारी रखें।",
    1: "रोग से बचाव हेतु प्रारंभिक फसल प्रबंधन की समीक्षा करें।",
    2: "सिंचाई अथवा पोषक तत्व प्रबंधन की समीक्षा आवश्यक है।",
    3: "रोग प्रबंधन और सुरक्षात्मक उपायों की समीक्षा की सलाह दी जाती है।",
    4: "सटीक परिणाम हेतु कृपया गेहूं पत्ती की एक और स्पष्ट फोटो लें।",
    5: "इस विषय पर नाभकृषि एआई (NabhKrishi AI) से परामर्श करें।",
}

# 24 environmental and weather features used by training environment
ENV_FEATURE_NAMES = [
    "PrevCropResidue",
    "SeedRate",
    "SowingDay",
    "BasalDAP",
    "BasalNPK",
    "BasalMOP",
    "BasalZn",
    "Split1Urea",
    "Split2Urea",
    "Split3Urea",
    "FirstIrrigationDay",
    "WeedingNumber",
    "Prcp_Monsoon",
    "Prcp_Oct",
    "Nov_Tmax",
    "EDD_Nov",
    "Dec_Tmax",
    "EDD_Dec",
    "Jan_Srad",
    "Feb_Srad",
    "Mar_Tmax",
    "EDD_Mar",
    "Latitude",
    "Longitude",
]

# Safe regional defaults for Bihar / Eastern UP wheat fields (5,689 fields dataset baseline)
DEFAULT_ENV_VALUES: Dict[str, float] = {
    "PrevCropResidue": 0.0,
    "SeedRate": 100.0,          # kg/ha
    "SowingDay": 315.0,         # day of year (mid-Nov)
    "BasalDAP": 100.0,          # kg/ha
    "BasalNPK": 0.0,
    "BasalMOP": 0.0,
    "BasalZn": 0.0,
    "Split1Urea": 100.0,        # kg/ha
    "Split2Urea": 100.0,        # kg/ha
    "Split3Urea": 50.0,         # kg/ha
    "FirstIrrigationDay": 22.0, # days after sowing (CRI stage)
    "WeedingNumber": 1.0,
    "Prcp_Monsoon": 803.2,      # mm
    "Prcp_Oct": 83.3,           # mm
    "Nov_Tmax": 28.2,           # °C
    "EDD_Nov": 10.0,
    "Dec_Tmax": 22.8,           # °C
    "EDD_Dec": 4.0,
    "Jan_Srad": 442.0,          # MJ/m²
    "Feb_Srad": 518.0,          # MJ/m²
    "Mar_Tmax": 31.5,           # °C
    "EDD_Mar": 10.0,
    "Latitude": 26.33,
    "Longitude": 83.54,
}

# Global loaded model instances
_ppo_model = None
_yield_model = None
_yield_preprocessor = None
_yield_features = None


# ============================================================
# 2. Risk & Irrigation Heuristics (Recovered from Environment)
# ============================================================

def calculate_disease_risk(context: Dict[str, float], stage: int) -> float:
    """Calculates simulated disease pressure risk based on weather and stage."""
    risk = 0.25
    prcp_oct = float(context.get("Prcp_Oct", DEFAULT_ENV_VALUES["Prcp_Oct"]))
    prcp_monsoon = float(context.get("Prcp_Monsoon", DEFAULT_ENV_VALUES["Prcp_Monsoon"]))
    nov_temp = float(context.get("Nov_Tmax", DEFAULT_ENV_VALUES["Nov_Tmax"]))
    dec_temp = float(context.get("Dec_Tmax", DEFAULT_ENV_VALUES["Dec_Tmax"]))

    if prcp_oct > 100:
        risk += 0.08
    if prcp_monsoon > 500:
        risk += 0.07
    if 15 <= nov_temp <= 30:
        risk += 0.03
    if 15 <= dec_temp <= 30:
        risk += 0.03
    if stage >= 2:
        risk += 0.05
    if stage >= 4:
        risk += 0.05

    return float(np.clip(risk, 0.10, 0.70))


def calculate_irrigation_need(irrigation_number: int, first_irrigation_day: float) -> float:
    """Calculates simulated irrigation-need score."""
    need = 0.50
    if irrigation_number < 2:
        need += 0.30
    elif irrigation_number <= 3:
        need += 0.05
    else:
        need -= 0.15

    if first_irrigation_day > 40 and first_irrigation_day > 0:
        need += 0.10

    return float(np.clip(need, 0.0, 1.0))


# ============================================================
# 3. Exact 60-Dimensional Observation Construction
# ============================================================

def build_ppo_observation(
    disease: Union[int, str],
    confidence: float,
    stage: int = 2,                       # Default: Tillering (stage 2/5 = 0.4)
    previous_action: int = -1,             # -1 indicates initial session (no action yet)
    baseline_yield: Optional[float] = None,
    simulated_yield: Optional[float] = None,
    irrigation_number: int = 3,
    field_context: Optional[Dict[str, float]] = None
) -> np.ndarray:
    """
    Constructs the exact 60-dimensional float32 observation expected by PPO V3.

    Structure:
    [0]     : Stage normalized (stage / 5.0)
    [1..15] : 15-class one-hot disease vector
    [16]    : Confidence clipped to [0.0, 1.0]
    [17..22]: 6-class one-hot previous action vector (all 0s if previous_action < 0)
    [23]    : Baseline yield normalized (baseline_yield / 8.0)
    [24]    : Simulated yield normalized (simulated_yield / 8.0)
    [25]    : Irrigation number normalized (irrigation_number / 6.0)
    [26]    : Disease risk clipped to [0.0, 1.0]
    [27]    : Irrigation need clipped to [0.0, 1.0]
    [28..51]: 24 environmental/weather features with exact training scalers
    [52..59]: 8 zeros (reserved padding slots)

    Returns:
        np.ndarray with shape (60,), dtype float32, bounded in [0.0, 1.0].
    """
    obs = np.zeros(60, dtype=np.float32)
    index = 0

    # 1. Stage (0..5)
    clamped_stage = int(np.clip(stage, 0, 5))
    obs[index] = clamped_stage / 5.0
    index += 1

    # 2. Disease one-hot (15 classes)
    disease_idx = -1
    if isinstance(disease, int):
        if 0 <= disease < len(DISEASES):
            disease_idx = disease
    elif isinstance(disease, str):
        cleaned = disease.lower().strip()
        if cleaned in DISEASES:
            disease_idx = DISEASES.index(cleaned)

    if disease_idx >= 0:
        obs[index + disease_idx] = 1.0
    index += len(DISEASES)  # index is now 16

    # 3. Confidence
    obs[index] = float(np.clip(confidence, 0.0, 1.0))
    index += 1  # index is now 17

    # 4. Previous action one-hot (6 actions)
    if 0 <= previous_action < 6:
        obs[index + previous_action] = 1.0
    index += 6  # index is now 23

    # Merge context with defaults
    ctx = dict(DEFAULT_ENV_VALUES)
    if field_context:
        ctx.update(field_context)

    # 5. Baseline yield
    if baseline_yield is None:
        # Default mean simulated yield from eastern India wheat dataset
        baseline_yield = 4.237
    obs[index] = float(np.clip(baseline_yield / 8.0, 0.0, 1.0))
    index += 1  # index is now 24

    # 6. Simulated yield (at initial step, matches baseline yield)
    if simulated_yield is None:
        simulated_yield = baseline_yield
    obs[index] = float(np.clip(simulated_yield / 8.0, 0.0, 1.0))
    index += 1  # index is now 25

    # 7. Irrigation number
    obs[index] = float(np.clip(irrigation_number / 6.0, 0.0, 1.0))
    index += 1  # index is now 26

    # 8. Disease risk
    d_risk = calculate_disease_risk(ctx, clamped_stage)
    obs[index] = float(np.clip(d_risk, 0.0, 1.0))
    index += 1  # index is now 27

    # 9. Irrigation need
    first_irrig_day = float(ctx.get("FirstIrrigationDay", DEFAULT_ENV_VALUES["FirstIrrigationDay"]))
    i_need = calculate_irrigation_need(irrigation_number, first_irrig_day)
    obs[index] = float(np.clip(i_need, 0.0, 1.0))
    index += 1  # index is now 28

    # 10. Environmental features (24 features, indices 28..51)
    for feature in ENV_FEATURE_NAMES:
        if index >= 60:
            break
        val = float(ctx.get(feature, DEFAULT_ENV_VALUES.get(feature, 0.0)))

        # Exact training normalizations
        if feature == "SeedRate":
            val /= 250.0
        elif feature in ["BasalDAP", "BasalNPK", "BasalMOP", "BasalZn"]:
            val /= 100.0
        elif feature in ["Split1Urea", "Split2Urea", "Split3Urea"]:
            val /= 100.0
        elif feature in ["Prcp_Monsoon", "Prcp_Oct"]:
            val /= 1000.0
        elif feature in ["Nov_Tmax", "Dec_Tmax", "Mar_Tmax"]:
            val /= 40.0
        elif feature in ["EDD_Nov", "EDD_Dec", "EDD_Mar"]:
            val /= 500.0
        elif feature in ["Jan_Srad", "Feb_Srad"]:
            val /= 30.0
        elif feature in ["SowingDay", "FirstIrrigationDay"]:
            val /= 150.0
        elif feature == "WeedingNumber":
            val /= 5.0
        elif feature == "PrevCropResidue":
            val /= 100.0
        elif feature == "Latitude":
            val = (val - 20.0) / 30.0
        elif feature == "Longitude":
            val = (val - 70.0) / 30.0
        else:
            val /= 100.0

        obs[index] = float(np.clip(val, 0.0, 1.0))
        index += 1

    # Indices 52..59 remain 0.0
    final_obs = np.clip(obs, 0.0, 1.0).astype(np.float32)

    # Strict observation validation
    validate_observation(final_obs)
    return final_obs


def validate_observation(obs: np.ndarray) -> None:
    """Validates type, shape, dtype, and numerical bounds of observation."""
    if not isinstance(obs, np.ndarray):
        raise TypeError(f"PPO observation must be a numpy.ndarray, got {type(obs)}")
    if obs.shape != (60,):
        raise ValueError(f"PPO observation must have shape (60,), got {obs.shape}")
    if obs.dtype != np.float32:
        raise TypeError(f"PPO observation must have dtype float32, got {obs.dtype}")
    if np.any(np.isnan(obs)) or np.any(np.isinf(obs)):
        raise ValueError("PPO observation contains NaN or Inf values.")
    if np.any(obs < 0.0) or np.any(obs > 1.0):
        raise ValueError("PPO observation contains values outside the expected [0.0, 1.0] range.")


# ============================================================
# 4. Model Loading and Inference
# ============================================================

def load_ppo_model(model_path: Optional[Path] = None):
    """
    Loads PPO V3 once into memory using Stable-Baselines3.
    """
    global _ppo_model
    if _ppo_model is not None:
        return _ppo_model

    path = model_path or DEFAULT_PPO_PATH
    if not path.exists():
        raise FileNotFoundError(
            f"PPO model archive not found at: {path}. "
            f"Please ensure nabhkrishi_ppo_v3.zip is present in gena_ai/models/."
        )

    try:
        from stable_baselines3 import PPO
        _ppo_model = PPO.load(str(path))
        logger.info(f"Loaded PPO V3 model successfully from {path}")
        return _ppo_model
    except Exception as e:
        logger.error(f"Failed to load PPO V3 with Stable-Baselines3: {e}")
        raise


def is_ppo_loaded() -> bool:
    """Checks whether PPO V3 is loaded in memory."""
    return _ppo_model is not None


def predict_decision(
    observation: np.ndarray,
    deterministic: bool = True
) -> Dict[str, Any]:
    """
    Performs deterministic decision-support inference with PPO V3.

    Args:
        observation: np.ndarray of shape (60,), dtype float32
        deterministic: True for production/demo decision path (no random sampling)

    Returns:
        Dict with action_id (0..5), action_name, and localized descriptions.
    """
    global _ppo_model
    validate_observation(observation)

    if _ppo_model is None:
        load_ppo_model()

    action, _state = _ppo_model.predict(
        observation,
        deterministic=deterministic
    )

    action_id = int(action)
    action_name = ACTION_MAP.get(action_id, "Monitor")

    return {
        "action_id": action_id,
        "action_name": action_name,
        "description_en": ACTION_DESCRIPTIONS_EN.get(action_id, ""),
        "description_hi": ACTION_DESCRIPTIONS_HI.get(action_id, ""),
    }
