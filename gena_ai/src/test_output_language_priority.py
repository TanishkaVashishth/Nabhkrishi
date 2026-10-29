import sys
import time
import uuid
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
    generate_answer_with_timing,
    detect_language,
    detect_language_details,
    extract_explicit_language_request,
    resolve_output_language,
    DEVANAGARI_MARATHI_TOKENS
)
from database import get_conversation_language, set_conversation_language

# ============================================================
# 1. Mandatory User Specification Tests
# ============================================================

MANDATORY_TESTS = [
    {
        "id": 1,
        "input": "What is yellow rust in wheat? Answer in Hindi.",
        "expected_target": "Hindi",
        "expected_script_range": (0x0900, 0x097F), # Devanagari
        "description": "English question -> Explicit Hindi request"
    },
    {
        "id": 2,
        "input": "What is yellow rust in wheat? Answer in Punjabi.",
        "expected_target": "Punjabi",
        "expected_script_range": (0x0A00, 0x0A7F), # Gurmukhi
        "description": "English question -> Explicit Punjabi request"
    },
    {
        "id": 3,
        "input": "What is yellow rust in wheat? Answer in Bengali.",
        "expected_target": "Bengali",
        "expected_script_range": (0x0980, 0x09FF), # Bengali
        "description": "English question -> Explicit Bengali request"
    },
    {
        "id": 4,
        "input": "गेहूं में पीला रतुआ क्या है? Answer in English.",
        "expected_target": "English",
        "expected_script_range": None, # ASCII / Latin
        "description": "Hindi Devanagari question -> Explicit English request"
    },
    {
        "id": 5,
        "input": "gehun mein yellow rust kya hai, Hindi mein answer do",
        "expected_target": "Hindi",
        "expected_script_range": (0x0900, 0x097F), # Devanagari
        "description": "Hinglish question -> Explicit Hindi request (Hindi mein answer do)"
    },
    {
        "id": 6,
        "input": "Explain aphids in wheat. Hindi mein batao.",
        "expected_target": "Hindi",
        "expected_script_range": (0x0900, 0x097F), # Devanagari
        "description": "English question -> Explicit Hindi request (Hindi mein batao)"
    }
]


def test_extraction_unit():
    print("=" * 80)
    print("SUITE 1: EXPLICIT LANGUAGE EXTRACTION UNIT TESTS")
    print("=" * 80)
    all_ok = True
    for item in MANDATORY_TESTS:
        explicit_lang, cleaned = extract_explicit_language_request(item["input"])
        passed = explicit_lang == item["expected_target"]
        status = "[PASS]" if passed else "[FAIL]"
        if not passed:
            all_ok = False
        print(f"{status} Test #{item['id']}: '{item['input']}'")
        print(f"       -> Extracted: {explicit_lang} | Cleaned: '{cleaned}'")
    assert all_ok, "Some explicit extraction unit tests failed!"
    print("\n>>> ALL EXPLICIT EXTRACTION UNIT TESTS PASSED!\n")


def test_priority_hierarchy():
    print("=" * 80)
    print("SUITE 2: 5-TIER LANGUAGE PRIORITY HIERARCHY TESTS")
    print("=" * 80)
    
    # Priority 1 beats Priority 2: Explicit request beats UI selected language
    target, expl, _ = resolve_output_language(
        question="What is yellow rust? Answer in Hindi.",
        ui_selected_language="English"
    )
    assert target == "Hindi", f"Expected Hindi (Priority 1 wins over UI), got {target}"
    print("[PASS] Priority 1 (Explicit Hindi) beats Priority 2 (UI English)")

    # Priority 1 beats Priority 3: Explicit request beats conversation history
    conv_id = f"test_conv_{uuid.uuid4()}"
    set_conversation_language(conv_id, "Hindi")
    target, expl, _ = resolve_output_language(
        question="Now answer in English.",
        conversation_id=conv_id
    )
    assert target == "English", f"Expected English (Priority 1 switch), got {target}"
    print("[PASS] Priority 1 (Explicit English switch) beats Priority 3 (Conv Hindi)")

    # Priority 2 beats Priority 3 (when no explicit and new conv)
    target, expl, _ = resolve_output_language(
        question="What is yellow rust?",
        ui_selected_language="Punjabi"
    )
    assert target == "Punjabi", f"Expected Punjabi (UI setting), got {target}"
    print("[PASS] Priority 2 (UI Punjabi) honored when no explicit request")

    # Priority 3 beats Priority 4: Short follow-up in English retains conversation Hindi
    conv_id2 = f"test_conv_{uuid.uuid4()}"
    set_conversation_language(conv_id2, "Hindi")
    target, expl, _ = resolve_output_language(
        question="How can I control it?",
        conversation_id=conv_id2
    )
    assert target == "Hindi", f"Expected Hindi (inherited from conv), got {target}"
    print("[PASS] Priority 3 (Conv Hindi) retained for follow-up question")

    # Priority 4: Detected user language when no explicit, no UI, no conv
    target, expl, _ = resolve_output_language(
        question="ਕਣਕ ਵਿੱਚ ਪੀਲੀ ਕੁੰਗੀ ਦੇ ਲੱਛਣ ਕੀ ਹਨ?"
    )
    assert target == "Punjabi", f"Expected Punjabi (detected input), got {target}"
    print("[PASS] Priority 4 (Detected Gurmukhi) used when no higher priority exists")

    # Priority 5: Fallback to English
    target, expl, _ = resolve_output_language(
        question="12345 ???"
    )
    assert target == "English", f"Expected English fallback, got {target}"
    print("[PASS] Priority 5 (English fallback) applied on unresolvable input")

    print("\n>>> ALL 5-TIER PRIORITY HIERARCHY TESTS PASSED!\n")


def test_live_mandatory_chatbot_calls(iterations=2):
    print("=" * 80)
    print(f"SUITE 3: LIVE END-TO-END RAG CHATBOT TESTS ({iterations} iterations each)")
    print("=" * 80)

    for run_idx in range(1, iterations + 1):
        print(f"\n--- RUN ITERATION {run_idx}/{iterations} ---")
        for item in MANDATORY_TESTS:
            q = item["input"]
            expected_target = item["expected_target"]
            print(f"\n[Testing #{item['id']} - Run {run_idx}] {item['description']}")
            print(f"Input: \"{q}\"")

            conv_id = f"test_e2e_{uuid.uuid4()}"
            t0 = time.perf_counter()
            answer, timings = generate_answer_with_timing(
                question=q,
                conversation_id=conv_id
            )
            elapsed = time.perf_counter() - t0

            # 1. Verify target language
            actual_target = timings.get("target_language")
            assert actual_target == expected_target, (
                f"Language mismatch! Expected: {expected_target}, Got: {actual_target}"
            )

            # 2. Verify script
            script_range = item["expected_script_range"]
            if script_range:
                has_script = any(script_range[0] <= ord(c) <= script_range[1] for c in answer)
                assert has_script, f"Expected characters in range {script_range} for {expected_target} in answer!"

            # 3. Verify Marathi safety guard (no Marathi tokens when Hindi requested)
            if expected_target == "Hindi":
                marathi_found = [tok for tok in DEVANAGARI_MARATHI_TOKENS if tok in answer]
                assert not marathi_found, f"Random Marathi tokens {marathi_found} found in Hindi answer!"

            print(f"-> Target Language: {actual_target} [OK]")
            print(f"-> Total Time: {elapsed:.2f}s (LLM: {timings.get('llm_generation', 0.0):.2f}s)")
            print(f"-> Answer Preview:\n   {answer[:160]}...")

    print("\n>>> ALL LIVE MANDATORY TESTS PASSED CLEANLY WITH ZERO MARATHI ANOMALIES!\n")


def test_multiturn_continuity():
    print("=" * 80)
    print("SUITE 4: MULTI-TURN CONVERSATION CONTINUITY & EXPLICIT SWITCH")
    print("=" * 80)

    conv_id = f"conv_multiturn_{uuid.uuid4()}"

    # Turn 1: User asks in English, explicitly requests Hindi
    q1 = "What is yellow rust in wheat? Answer in Hindi."
    print(f"\nTurn 1: Farmer: '{q1}'")
    ans1, t1 = generate_answer_with_timing(q1, conversation_id=conv_id)
    print(f"Bot (target={t1['target_language']}): {ans1[:120]}...")
    assert t1["target_language"] == "Hindi", f"Expected Hindi on Turn 1, got {t1['target_language']}"
    assert any(0x0900 <= ord(c) <= 0x097F for c in ans1), "Expected Devanagari in Turn 1"

    # Turn 2: User asks follow-up in English WITHOUT language directive
    q2 = "How can I control it?"
    print(f"\nTurn 2: Farmer: '{q2}' (No explicit language directive)")
    ans2, t2 = generate_answer_with_timing(q2, conversation_id=conv_id)
    print(f"Bot (target={t2['target_language']}): {ans2[:120]}...")
    assert t2["target_language"] == "Hindi", (
        f"Expected Hindi continuity on Turn 2, got {t2['target_language']}"
    )
    assert any(0x0900 <= ord(c) <= 0x097F for c in ans2), "Expected Devanagari in Turn 2"

    # Turn 3: User explicitly switches to English
    q3 = "Now answer in English."
    print(f"\nTurn 3: Farmer: '{q3}' (Explicit switch to English)")
    ans3, t3 = generate_answer_with_timing(q3, conversation_id=conv_id)
    print(f"Bot (target={t3['target_language']}): {ans3[:120]}...")
    assert t3["target_language"] == "English", (
        f"Expected English on Turn 3, got {t3['target_language']}"
    )

    print("\n>>> MULTI-TURN CONTINUITY & SWITCHING TESTS PASSED!\n")


if __name__ == "__main__":
    t_start = time.perf_counter()
    test_extraction_unit()
    test_priority_hierarchy()
    test_multiturn_continuity()
    test_live_mandatory_chatbot_calls(iterations=2)
    total_time = time.perf_counter() - t_start
    print("=" * 80)
    print(f"ALL TESTS PASSED SUCCESSFULLY in {total_time:.2f}s!")
    print("=" * 80)
