import sys
from pathlib import Path

SRC_DIR = Path(__file__).resolve().parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from fastapi.testclient import TestClient
from api import app

client = TestClient(app)

tests = [
    {
        "message": "What is yellow rust in wheat? Answer in Hindi.",
        "expected": "Hindi",
        "description": "Explicit Hindi directive"
    },
    {
        "message": "गेहूं में पीला रतुआ क्या है? Answer in English.",
        "expected": "English",
        "description": "Explicit English directive"
    },
    {
        "message": "What is yellow rust in wheat?",
        "language": "Punjabi",
        "expected": "Punjabi",
        "description": "UI Selected language = Punjabi"
    }
]

print("=" * 80)
print("TESTING FASTAPI /chat ENDPOINT INTEGRATION")
print("=" * 80)

for t in tests:
    print(f"\nTesting: {t['description']}")
    payload = {"message": t["message"]}
    if "language" in t:
        payload["language"] = t["language"]
    resp = client.post("/chat", json=payload)
    assert resp.status_code == 200, f"HTTP {resp.status_code}: {resp.text}"
    data = resp.json()
    print(f"Input: \"{t['message']}\" (UI Language: {t.get('language')})")
    print(f"-> Returned Language: {data['language']}")
    print(f"-> Answer Preview:\n   {data['answer'][:120]}...")
    assert data["language"] == t["expected"], f"Expected {t['expected']}, got {data['language']}"
    print("[PASS]")

print("\n" + "=" * 80)
print("ALL FASTAPI ENDPOINT TESTS PASSED SUCCESSFULLY!")
print("=" * 80)
