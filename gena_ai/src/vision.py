import io
import os
from pathlib import Path
from typing import Dict, Any, List, Optional

import torch
import torch.nn as nn
from PIL import Image
import torchvision.transforms as transforms
import torchvision.models as models

# ============================================================
# 1. Configuration & Constants
# ============================================================

SRC_DIR = Path(__file__).resolve().parent
GENA_AI_DIR = SRC_DIR.parent
DEFAULT_MODEL_PATH = GENA_AI_DIR / "models" / "best_swin_t_wheat_fixed.pth"

# Exact 15-class mapping specified for this model
CLASS_NAMES: List[str] = [
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

NUM_CLASSES = len(CLASS_NAMES)
INPUT_RESOLUTION = (224, 224)

# ImageNet normalization standard
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]

# Transforms pipeline used during evaluation
transform_pipeline = transforms.Compose([
    transforms.Resize(INPUT_RESOLUTION),
    transforms.ToTensor(),
    transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
])

# Global model cache (loaded once at startup)
_global_model: Optional[nn.Module] = None
_device: torch.device = torch.device("cpu")


# ============================================================
# 2. Model Architecture & Loading
# ============================================================

def build_swin_t_model(num_classes: int = NUM_CLASSES) -> nn.Module:
    """
    Construct the Swin Transformer Tiny architecture with a custom classification head.
    Linear(in_features=768, out_features=15)
    """
    model = models.swin_t(weights=None)
    in_features = model.head.in_features  # 768
    model.head = nn.Linear(in_features, num_classes)
    return model


def get_model_path() -> Path:
    """Resolve model path from environment variable or standard location."""
    configured_path = os.getenv("VISION_MODEL_PATH")
    if configured_path:
        p = Path(configured_path)
        if p.exists():
            return p
    return DEFAULT_MODEL_PATH


def load_vision_model(model_path: Optional[Path] = None) -> nn.Module:
    """
    Load the Swin-T model once into memory and set model.eval().
    """
    global _global_model, _device

    if _global_model is not None:
        return _global_model

    path = model_path or get_model_path()
    if not path.exists():
        raise FileNotFoundError(
            f"Vision model checkpoint not found at: {path}. "
            f"Please ensure best_swin_t_wheat_fixed.pth is present."
        )

    _device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = build_swin_t_model(num_classes=NUM_CLASSES)

    checkpoint = torch.load(str(path), map_location=_device)

    # Extract state dict
    if isinstance(checkpoint, dict):
        if "model_state_dict" in checkpoint:
            state_dict = checkpoint["model_state_dict"]
        elif "state_dict" in checkpoint:
            state_dict = checkpoint["state_dict"]
        else:
            state_dict = checkpoint
    else:
        state_dict = checkpoint

    model.load_state_dict(state_dict)
    model.to(_device)
    model.eval()

    _global_model = model
    print(f"Loaded Swin-T wheat disease vision model successfully from {path} (device: {_device})")
    return _global_model


def is_model_loaded() -> bool:
    """Check whether the vision model is currently loaded in memory."""
    return _global_model is not None


# ============================================================
# 3. Preprocessing & Inference
# ============================================================

def preprocess_image(image_input: Any) -> torch.Tensor:
    """
    Validate and preprocess image for Swin-T inference:
    1. Load image (bytes or PIL Image)
    2. Convert to RGB
    3. Resize to 224 x 224
    4. Convert to tensor
    5. Normalize using ImageNet mean & std
    """
    if isinstance(image_input, (bytes, bytearray)):
        if len(image_input) == 0:
            raise ValueError("Provided image data is empty.")
        try:
            pil_image = Image.open(io.BytesIO(image_input))
        except Exception as e:
            raise ValueError(f"Invalid or corrupted image format: {e}")
    elif isinstance(image_input, Image.Image):
        pil_image = image_input
    else:
        raise ValueError("Unsupported image input type. Expected bytes or PIL Image.")

    # Convert to RGB (handles RGBA, grayscale, CMYK, etc.)
    if pil_image.mode != "RGB":
        pil_image = pil_image.convert("RGB")

    tensor = transform_pipeline(pil_image)
    # Add batch dimension: [1, 3, 224, 224]
    return tensor.unsqueeze(0)


def predict_wheat_disease(
    image_input: Any,
    top_k: int = 3
) -> Dict[str, Any]:
    """
    Perform Swin-T inference on an input wheat leaf image.
    
    Returns:
        Dict with keys:
            'class_id': int (0-14)
            'class_name': str
            'confidence': float (0.0 to 1.0)
            'top_predictions': list of top_k dicts
    """
    model = load_vision_model()
    tensor = preprocess_image(image_input).to(_device)

    with torch.no_grad():
        logits = model(tensor)
        probabilities = torch.softmax(logits, dim=1).squeeze(0)

    # Top prediction
    top_conf, top_idx = torch.topk(probabilities, k=min(top_k, NUM_CLASSES))

    top_predictions: List[Dict[str, Any]] = []
    for score, idx in zip(top_conf.tolist(), top_idx.tolist()):
        top_predictions.append({
            "class_id": int(idx),
            "class_name": CLASS_NAMES[idx],
            "confidence": round(float(score), 4),
        })

    primary = top_predictions[0]

    return {
        "class_id": primary["class_id"],
        "class_name": primary["class_name"],
        "confidence": primary["confidence"],
        "top_predictions": top_predictions,
    }
