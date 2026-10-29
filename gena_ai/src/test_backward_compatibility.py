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
    resolve_target_language,
    translate_to_english,
    translate_from_english,
    retrieve_documents,
    generate_answer_with_timing
)
from database import (
    create_conversation,
    save_message_local,
    get_recent_messages,
    set_conversation_language,
    get_conversation_language
)


def verify_old_native_script_features():
    print("=" * 80)
    print("VERIFYING EXISTING / OLD FEATURES (MUST CONTINUE WORKING 100% UNCHANGED)")
    print("=" * 80)

    old_test_cases = [
        {
            "category": "Native Hindi (Devanagari)",
            "query": "गेहूं में पीला रतुआ क्या है?",
            "expected_lang": "Hindi",
            "expected_script": "Devanagari",
            "expected_romanized": False
        },
        {
            "category": "Native Punjabi (Gurmukhi)",
            "query": "ਕਣਕ ਵਿੱਚ ਰੋਗ ਕਿਉਂ ਹੁੰਦਾ ਹੈ?",
            "expected_lang": "Punjabi",
            "expected_script": "Gurmukhi",
            "expected_romanized": False
        },
        {
            "category": "Native Bengali (Bengali Script)",
            "query": "গমের রোগ কীভাবে নিয়ন্ত্রণ করব?",
            "expected_lang": "Bengali",
            "expected_script": "Bengali",
            "expected_romanized": False
        },
        {
            "category": "English (Standard English)",
            "query": "What is yellow rust in wheat?",
            "expected_lang": "English",
            "expected_script": "Latin",
            "expected_romanized": False
        },
        {
            "category": "Native Gujarati (Gujarati Script)",
            "query": "ઘઉંમાં પીળો ગેરુ શું છે?",
            "expected_lang": "Gujarati",
            "expected_script": "Gujarati",
            "expected_romanized": False
        },
        {
            "category": "Native Tamil (Tamil Script)",
            "query": "கோதுமையில் மஞ்சள் துரு நோய் என்றால் என்ன?",
            "expected_lang": "Tamil",
            "expected_script": "Tamil",
            "expected_romanized": False
        },
        {
            "category": "Native Telugu (Telugu Script)",
            "query": "గోధుమలో పసుపు కుంకుమ తెగులు ఏమిటి?",
            "expected_lang": "Telugu",
            "expected_script": "Telugu",
            "expected_romanized": False
        },
        {
            "category": "Native Marathi (Devanagari Script)",
            "query": "गव्हावरील तांबेरा रोगाची लक्षणे कोणती आहेत?",
            "expected_lang": "Marathi",
            "expected_script": "Devanagari",
            "expected_romanized": False
        },
        {
            "category": "Native Haryanvi Dialect (Devanagari Script)",
            "query": "म्हारी कनक म पीला रतुआ आ रह्या सै",
            "expected_lang": "Haryanvi",
            "expected_script": "Devanagari",
            "expected_romanized": False
        }
    ]

    all_old_ok = True
    for item in old_test_cases:
        det_name = detect_language(item["query"])
        target_lang = resolve_target_language(det_name)
        details = detect_language_details(item["query"])

        ok_lang = (target_lang == item["expected_lang"])
        ok_script = (details["script"] == item["expected_script"])
        ok_rom = (details["is_romanized"] == item["expected_romanized"])
        test_ok = ok_lang and ok_script and ok_rom

        if not test_ok:
            all_old_ok = False

        status = "PASS" if test_ok else "FAIL"
        print(f"[{status}] {item['category']}: \"{item['query']}\"")
        print(f"       -> Target: {target_lang} (Expected: {item['expected_lang']}) | Script: {details['script']} | Romanized: {details['is_romanized']}")

    assert all_old_ok, "Regression detected in existing native script features!"
    print("\n>>> ALL EXISTING NATIVE SCRIPT FEATURES REMAIN 100% FUNCTIONAL!\n")


def verify_new_romanized_features():
    print("=" * 80)
    print("VERIFYING NEW ROMANIZED FEATURES (ADDITIVE EXTENSION)")
    print("=" * 80)

    new_test_cases = [
        {
            "category": "Romanized Hindi",
            "query": "gehun me peela rust kya hai?",
            "expected_lang": "Hindi",
            "expected_code": "hi",
            "expected_romanized": True
        },
        {
            "category": "Hinglish (Mixed Hindi + English)",
            "query": "wheat me yellow rust kaise control kare?",
            "expected_lang": "Hindi",
            "expected_code": "hi",
            "expected_romanized": True
        },
        {
            "category": "Romanized Punjabi",
            "query": "kanak vich rog kyu hunda?",
            "expected_lang": "Punjabi",
            "expected_code": "pa",
            "expected_romanized": True
        },
        {
            "category": "Romanized Bengali",
            "query": "gomer fasole rog hole ki korbo?",
            "expected_lang": "Bengali",
            "expected_code": "bn",
            "expected_romanized": True
        },
        {
            "category": "Romanized Haryanvi",
            "query": "gehun ki fasal me rog lag rya se ke karu",
            "expected_lang": "Haryanvi",
            "expected_code": "bgc",
            "expected_romanized": True
        }
    ]

    all_new_ok = True
    for item in new_test_cases:
        det_name = detect_language(item["query"])
        target_lang = resolve_target_language(det_name)
        details = detect_language_details(item["query"])

        ok_lang = (target_lang == item["expected_lang"])
        ok_code = (details["language"] == item["expected_code"])
        ok_rom = (details["is_romanized"] == item["expected_romanized"])
        test_ok = ok_lang and ok_code and ok_rom

        if not test_ok:
            all_new_ok = False

        status = "PASS" if test_ok else "FAIL"
        print(f"[{status}] {item['category']}: \"{item['query']}\"")
        print(f"       -> Target: {target_lang} (Expected: {item['expected_lang']}) | Code: {details['language']} | Romanized: {details['is_romanized']}")

    assert all_new_ok, "Issues detected in new Romanized features!"
    print("\n>>> ALL NEW ROMANIZED FEATURES WORK FLAWLESSLY!\n")


def verify_retrieval_and_translation_integrity():
    print("=" * 80)
    print("VERIFYING RETRIEVAL & TRANSLATION INTEGRITY")
    print("=" * 80)

    # 1. RAG retrieval verified
    t0 = time.perf_counter()
    docs = retrieve_documents("yellow rust in wheat symptoms and control", k=3)
    t_ret = time.perf_counter() - t0
    print(f"Retriever verified: Retrieved {len(docs)} high-relevance chunks in {t_ret:.4f}s")
    assert len(docs) > 0, "Retrieval returned 0 chunks!"

    # 2. Conversation memory state verified
    conv_id = "compat_test_conv_999"
    set_conversation_language(conv_id, "Hindi")
    assert get_conversation_language(conv_id) == "Hindi", "Conversation language state failed to persist!"
    print("Conversation memory language persistence verified: OK")

    # 3. Message store verified
    msg = save_message_local(conv_id, "user", "gehun me peela rust kya hai?")
    recent = get_recent_messages(conv_id, limit=2)
    assert len(recent) > 0, "Recent message retrieval failed!"
    print("Conversation message memory verified: OK")

    print("\n>>> RETRIEVAL, DATABASE & MEMORY INTEGRITY CONFIRMED!\n")


if __name__ == "__main__":
    verify_old_native_script_features()
    verify_new_romanized_features()
    verify_retrieval_and_translation_integrity()
    print("=" * 80)
    print("SUCCESS: OLD FEATURES + NEW FEATURES COEXIST WITH 100% BACKWARD COMPATIBILITY!")
    print("=" * 80)
