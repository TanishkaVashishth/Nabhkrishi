import sys
import time
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

from chatbot import (
    detect_language,
    detect_language_details,
    resolve_target_language
)
from database import set_conversation_language, get_conversation_language

# 13 Required test cases from user specification
TEST_CASES_13 = [
    {
        "id": 1,
        "input": "गेहूं में पीला रतुआ क्या है?",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": False
    },
    {
        "id": 2,
        "input": "gehun mein peela ratua kya hai?",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": True
    },
    {
        "id": 3,
        "input": "gehun me yellow rust kaise control kare",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": True
    },
    {
        "id": 4,
        "input": "wheat me yellow rust kaise control karein?",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": True
    },
    {
        "id": 5,
        "input": "What is yellow rust in wheat?",
        "expected_lang": "English",
        "expected_code": "en",
        "is_romanized": False
    },
    {
        "id": 6,
        "input": "गेहूं में aphid कैसे रोकें?",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": False
    },
    {
        "id": 7,
        "input": "aphid ko kaise control kare",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": True
    },
    {
        "id": 8,
        "input": "bhai gehun ki fasal me aphid aa gaya hai kya karu",
        "expected_lang": "Hindi",
        "expected_code": "hi",
        "is_romanized": True
    },
    {
        "id": 9,
        "input": "kanak vich rog kyu hunda",
        "expected_lang": "Punjabi",
        "expected_code": "pa",
        "is_romanized": True
    },
    {
        "id": 10,
        "input": "ਕਣਕ ਵਿੱਚ ਰੋਗ ਕਿਉਂ ਹੁੰਦਾ ਹੈ?",
        "expected_lang": "Punjabi",
        "expected_code": "pa",
        "is_romanized": False
    },
    {
        "id": 11,
        "input": "গমের রোগ কীভাবে নিয়ন্ত্রণ করব?",
        "expected_lang": "Bengali",
        "expected_code": "bn",
        "is_romanized": False
    },
    {
        "id": 12,
        "input": "gomer fasole rog hole ki korbo",
        "expected_lang": "Bengali",
        "expected_code": "bn",
        "is_romanized": True
    },
    {
        "id": 13,
        "input": "gehun ki fasal me rog lag rya se ke karu",
        "expected_lang": "Haryanvi",
        "expected_code": "bgc",
        "is_romanized": True
    }
]


def test_13_required_cases():
    print("=" * 80)
    print("TEST SUITE 1: 13 SPECIFIED TEST CASES (NATIVE & ROMANIZED)")
    print("=" * 80)
    all_passed = True

    for tc in TEST_CASES_13:
        q = tc["input"]
        expected_lang = tc["expected_lang"]
        expected_code = tc["expected_code"]
        expected_romanized = tc["is_romanized"]

        details = detect_language_details(q)
        detected_name = detect_language(q)
        target_lang = resolve_target_language(detected_name)

        ok_lang = (target_lang == expected_lang)
        ok_code = (details["language"] == expected_code)
        ok_rom = (details["is_romanized"] == expected_romanized)
        test_passed = ok_lang and ok_code and ok_rom

        if not test_passed:
            all_passed = False

        status = "PASS" if test_passed else "FAIL"
        print(f"[{status}] Test #{tc['id']:02d}: \"{q}\"")
        print(f"       -> Target: {target_lang} (Expected: {expected_lang})")
        print(f"       -> Code: {details['language']} (Expected: {expected_code}) | is_romanized: {details['is_romanized']} | conf: {details['confidence']:.2f}")

    assert all_passed, "Some of the 13 required test cases failed!"
    print("\n>>> ALL 13 TEST CASES PASSED PERFECTLY!\n")


def test_conversation_continuity_and_switching():
    print("=" * 80)
    print("TEST SUITE 2: CONVERSATION LANGUAGE CONTINUITY & SWITCHING")
    print("=" * 80)
    conv_id = "test_conv_continuity_123"

    # Turn 1: User asks in Romanized Hindi
    t1_q = "gehun me peela rust kya hai?"
    t1_lang = detect_language(t1_q, conversation_id=conv_id)
    set_conversation_language(conv_id, t1_lang)
    print(f"Turn 1: \"{t1_q}\" -> {t1_lang}")
    assert t1_lang == "Hindi", f"Expected Hindi, got {t1_lang}"

    # Turn 2: Follow-up question with ambiguous / short context
    t2_q = "iska ilaj kya hai?"
    t2_lang = detect_language(t2_q, conversation_id=conv_id)
    set_conversation_language(conv_id, t2_lang)
    print(f"Turn 2 (follow-up): \"{t2_q}\" -> {t2_lang}")
    assert t2_lang == "Hindi", f"Expected continuity in Hindi, got {t2_lang}"

    # Turn 3: User explicitly switches to English
    t3_q = "What is the scientific name?"
    t3_lang = detect_language(t3_q, conversation_id=conv_id)
    set_conversation_language(conv_id, t3_lang)
    print(f"Turn 3 (explicit switch): \"{t3_q}\" -> {t3_lang}")
    assert t3_lang == "English", f"Expected switch to English, got {t3_lang}"

    # Turn 4: User explicitly switches back to Hindi
    t4_q = "isko kaise rok sakte hain"
    t4_lang = detect_language(t4_q, conversation_id=conv_id)
    set_conversation_language(conv_id, t4_lang)
    print(f"Turn 4 (switch back): \"{t4_q}\" -> {t4_lang}")
    assert t4_lang == "Hindi", f"Expected switch back to Hindi, got {t4_lang}"

    print("\n>>> CONVERSATION CONTINUITY & SWITCHING TESTS PASSED!\n")


def test_performance_latency():
    print("=" * 80)
    print("TEST SUITE 3: DETECTION LATENCY BENCHMARK (< 1ms requirement)")
    print("=" * 80)
    iterations = 200
    queries = [tc["input"] for tc in TEST_CASES_13]

    t0 = time.perf_counter()
    for _ in range(iterations):
        for q in queries:
            _ = detect_language_details(q)
    total_time = time.perf_counter() - t0
    total_queries = iterations * len(queries)
    avg_latency_ms = (total_time / total_queries) * 1000.0

    print(f"Total queries evaluated: {total_queries}")
    print(f"Total execution time: {total_time:.4f}s")
    print(f"Average latency per language detection: {avg_latency_ms:.4f} ms")

    assert avg_latency_ms < 1.0, f"Language detection latency too high: {avg_latency_ms:.4f} ms (expected < 1.0 ms)"
    print(f"\n>>> SPEED TEST PASSED: Sub-millisecond latency achieved ({avg_latency_ms:.4f} ms/query)!\n")


if __name__ == "__main__":
    test_13_required_cases()
    test_conversation_continuity_and_switching()
    test_performance_latency()
    print("=" * 80)
    print("ALL ROMANIZED & MULTILINGUAL TESTS PASSED SUCCESSFULLY!")
    print("=" * 80)
