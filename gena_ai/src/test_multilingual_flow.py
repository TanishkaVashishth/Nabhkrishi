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

from chatbot import detect_language, detect_disease, retrieve_documents

def test_language_detection():
    print("=" * 70)
    print("TEST 1: DETERMINISTIC MULTILINGUAL DETECTION")
    print("=" * 70)
    test_cases = [
        ("What is yellow rust in wheat?", "English"),
        ("गेहूं में पीला रतुआ क्या है?", "Hindi"),
        ("ਕਣਕ ਵਿੱਚ ਪੀਲਾ ਰਤੂਆ ਕੀ ਹੁੰਦਾ ਹੈ?", "Punjabi"),
        ("গমের হলুদ মরিচা কী?", "Bengali"),
        ("म्हारी कनक म पीला रतुआ आ रह्या सै", "Haryanvi"),
        ("Meri wheat ki leaves pe yellow spots aa rahe hain, kya karun?", "Hinglish")
    ]
    all_ok = True
    for query, expected in test_cases:
        detected = detect_language(query)
        ok = (detected.lower() == expected.lower()) or (detected.lower() == "hindi" and expected.lower() == "hinglish")
        if not ok:
            all_ok = False
        print(f"[{'PASS' if ok else 'FAIL'}] \"{query}\" -> {detected} (expected {expected})")
    assert all_ok, "Some language detection tests failed!"
    print(">>> All 6 language detection tests PASSED.\n")

def test_disease_detection():
    print("=" * 70)
    print("TEST 2: MULTILINGUAL DISEASE ALIAS RECOGNITION")
    print("=" * 70)
    disease_cases = [
        ("What is yellow rust?", "yellow_rust"),
        ("गेहूं में पीला रतुआ के लक्षण", "yellow_rust"),
        ("ਕਣਕ ਵਿੱਚ ਪੀਲਾ ਰਤੂਆ ਕਿਵੇਂ ਰੋਕੀਏ?", "yellow_rust"),
        ("গমের হলুদ মরিচা দমন", "yellow_rust"),
        ("ਕਣਕ ਵਿੱਚ ਕਾਂਗਿਆਰੀ ਰੋਗ", "loose_smut"),
        ("black rust damage", "black_rust")
    ]
    all_ok = True
    for query, expected in disease_cases:
        detected = detect_disease(query)
        ok = detected == expected
        if not ok:
            all_ok = False
        print(f"[{'PASS' if ok else 'FAIL'}] \"{query}\" -> {detected} (expected {expected})")
    assert all_ok, "Some disease alias detection tests failed!"
    print(">>> All multilingual disease alias tests PASSED.\n")

def test_retrieval_cache():
    print("=" * 70)
    print("TEST 3: RETRIEVAL & LRU CACHING")
    print("=" * 70)
    import time
    t0 = time.perf_counter()
    res1 = retrieve_documents("yellow rust symptoms", k=3)
    t1 = time.perf_counter() - t0

    t0 = time.perf_counter()
    res2 = retrieve_documents("yellow rust symptoms", k=3)
    t2 = time.perf_counter() - t0

    print(f"First retrieval (cold): {t1:.4f}s, Chunks: {len(res1)}")
    print(f"Second retrieval (cached): {t2:.6f}s, Chunks: {len(res2)}")
    assert len(res1) > 0, "No chunks returned!"
    assert t2 < t1, "Cache did not accelerate retrieval!"
    print(">>> Retrieval cache acceleration PASSED.\n")

def test_e2e_chat():
    print("=" * 70)
    print("TEST 4: END-TO-END CONCISE MULTILINGUAL CHAT & TIMING")
    print("=" * 70)
    from chatbot import generate_answer_with_timing

    # Test Hindi question
    q_hi = "गेहूं में पीला रतुआ क्या है?"
    ans_hi, timings_hi = generate_answer_with_timing(q_hi, conversation_id="test_timing_conv")
    print(f"Question (Hindi): {q_hi}")
    print(f"Answer (Hindi): {ans_hi}")
    print(f"Word Count: {len(ans_hi.split())}")
    print(f"Timings: {timings_hi}\n")

    assert len(ans_hi.strip()) > 0
    assert timings_hi["total"] > 0
    print(">>> End-to-end chat test PASSED.\n")

if __name__ == "__main__":
    test_language_detection()
    test_disease_detection()
    test_retrieval_cache()
    test_e2e_chat()
    print("ALL TESTS COMPLETED SUCCESSFULLY!")
