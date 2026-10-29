import io
import sys
from pathlib import Path
from PIL import Image

SRC_DIR = Path(__file__).resolve().parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from fastapi.testclient import TestClient
from api import app
from vision import CLASS_NAMES, NUM_CLASSES, load_vision_model

client = TestClient(app)

def run_vision_tests():
    print("=" * 80)
    print("TESTING SWIN-T WHEAT DISEASE VISION PIPELINE & API")
    print("=" * 80)

    # 1. Model architecture verification
    print("\n[Test 1] Verifying Model Architecture & Head...")
    model = load_vision_model()
    assert model is not None, "Model failed to load!"
    assert hasattr(model, "head"), "Model does not have classification head!"
    assert model.head.out_features == 15, f"Expected 15 out features, got {model.head.out_features}"
    assert model.head.in_features == 768, f"Expected 768 in features, got {model.head.in_features}"
    assert len(CLASS_NAMES) == 15, f"Expected 15 classes, got {len(CLASS_NAMES)}"
    print("✓ Model architecture verified: Swin-T with Linear(768, 15)")

    # 2. Health check endpoint verification
    print("\n[Test 2] Verifying /health endpoint...")
    resp = client.get("/health")
    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}"
    data = resp.json()
    assert data.get("status") in ("ok", "healthy")
    assert data.get("vision_model_loaded") is True, f"Expected vision_model_loaded=True, got {data}"
    print(f"✓ /health verified: {data}")

    # 3. Predict endpoint with valid synthetic image
    print("\n[Test 3] Testing /predict with valid JPEG image...")
    img = Image.new("RGB", (224, 224), color=(120, 160, 60))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    buf.seek(0)

    files = {"image": ("test_wheat_leaf.jpg", buf.getvalue(), "image/jpeg")}
    resp = client.post("/predict", files=files)
    assert resp.status_code == 200, f"Predict failed: {resp.status_code} - {resp.text}"
    body = resp.json()
    assert body.get("success") is True, "Expected success=True"
    pred = body.get("prediction")
    assert pred is not None, "Missing prediction in response"
    class_id = pred.get("class_id")
    class_name = pred.get("class_name")
    confidence = pred.get("confidence")

    assert 0 <= class_id <= 14, f"Class ID {class_id} out of range 0-14"
    assert class_name in CLASS_NAMES, f"Class name {class_name} not in CLASS_NAMES"
    assert CLASS_NAMES[class_id] == class_name, f"Mismatch: ID {class_id} vs name {class_name}"
    assert 0.0 <= confidence <= 1.0, f"Confidence {confidence} out of range [0, 1]"

    top_preds = body.get("top_predictions", [])
    assert len(top_preds) > 0, "No top predictions returned"
    print(f"✓ Prediction result: ID={class_id}, Name='{class_name}', Confidence={confidence:.2%}")
    print(f"✓ Top predictions: {top_preds}")

    # 4. Predict endpoint with real wheat leaf image if present
    real_wheat = Path("C:/Users/shash/Downloads/wheat-stem-rust-rwanda-1.jpg")
    if real_wheat.exists():
        print(f"\n[Test 4] Testing /predict with real leaf image: {real_wheat.name}...")
        with open(real_wheat, "rb") as f:
            real_bytes = f.read()
        resp = client.post("/predict", files={"image": ("wheat_rust.jpg", real_bytes, "image/jpeg")})
        assert resp.status_code == 200, f"Real image failed: {resp.status_code} - {resp.text}"
        real_body = resp.json()
        real_pred = real_body["prediction"]
        print(f"✓ Real image result: {real_pred['class_name']} ({real_pred['confidence']:.2%})")

    # 5. Invalid / corrupt image handling
    print("\n[Test 5] Testing invalid / corrupt image handling...")
    corrupt_files = {"image": ("corrupt.jpg", b"not-a-valid-image-bytes", "image/jpeg")}
    resp = client.post("/predict", files=corrupt_files)
    assert resp.status_code == 400, f"Expected 400 for corrupt image, got {resp.status_code}"
    print(f"✓ Corrupt image rejected with 400: {resp.json().get('detail')}")

    # 6. Empty image file handling
    print("\n[Test 6] Testing empty image file handling...")
    empty_files = {"image": ("empty.jpg", b"", "image/jpeg")}
    resp = client.post("/predict", files=empty_files)
    assert resp.status_code == 400, f"Expected 400 for empty image, got {resp.status_code}"
    print(f"✓ Empty image rejected with 400: {resp.json().get('detail')}")

    # 7. Missing image field handling
    print("\n[Test 7] Testing missing image field...")
    resp = client.post("/predict", data={"other_field": "val"})
    assert resp.status_code == 422, f"Expected 422 for missing field, got {resp.status_code}"
    print(f"✓ Missing image field rejected with 422")

    print("\n" + "=" * 80)
    print("ALL VISION PIPELINE TESTS PASSED!")
    print("=" * 80)

if __name__ == "__main__":
    run_vision_tests()
