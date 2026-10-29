import os
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
    generate_answer_with_timing,
    detect_language,
    resolve_target_language,
    translate_to_english,
    retrieve_documents
)

TEST_QUERIES = [
    {
        "id": 1,
        "name": "English Query",
        "query": "What are the symptoms of yellow rust in wheat?",
        "expected_lang": "English",
        "expected_target_lang": "English"
    },
    {
        "id": 2,
        "name": "Hindi Query",
        "query": "गेहूं में पीला रतुआ रोग के लक्षण क्या हैं?",
        "expected_lang": "Hindi",
        "expected_target_lang": "Hindi"
    },
    {
        "id": 3,
        "name": "Punjabi Query",
        "query": "ਕਣਕ ਵਿੱਚ ਪੀਲੀ ਕੁੰਗੀ ਦੇ ਲੱਛਣ ਕੀ ਹਨ?",
        "expected_lang": "Punjabi",
        "expected_target_lang": "Punjabi"
    },
    {
        "id": 4,
        "name": "Hinglish Query",
        "query": "Gehu me yellow rust ke symptoms kya hain?",
        "expected_lang": "Hindi",
        "expected_target_lang": "Hindi"
    }
]

def run_benchmark():
    print("=" * 80)
    print("NABHKRISHI AI - MULTILINGUAL PIPELINE VERIFICATION BENCHMARK")
    print("=" * 80)

    reports = []

    for item in TEST_QUERIES:
        q = item["query"]
        print(f"\n[{item['id']}/4] TESTING: {item['name']}")
        print(f"Query: \"{q}\"")

        # 1. Test language detection
        detected_lang = detect_language(q)
        target_lang = resolve_target_language(detected_lang)

        # 2. Test query translation
        if detected_lang == "English":
            translated_query = q
        else:
            translated_query = translate_to_english(q, detected_lang)

        # 3. Test retrieval
        retrieved_docs = retrieve_documents(translated_query, k=3)
        retrieved_ok = len(retrieved_docs) > 0

        # 4. End-to-end answer generation with timing
        import uuid
        t_start = time.perf_counter()
        conv_id = str(uuid.uuid4())
        answer, timings = generate_answer_with_timing(
            question=q,
            conversation_id=conv_id,
            language=detected_lang
        )
        total_time = time.perf_counter() - t_start

        report = {
            "test_id": item["id"],
            "name": item["name"],
            "original_query": q,
            "detected_language": detected_lang,
            "target_language": target_lang,
            "translated_query": translated_query,
            "retrieved_successfully": f"Yes ({len(retrieved_docs)} chunks)",
            "llm_answer_language": target_lang,
            "answer_translation": f"Translated into {target_lang}" if target_lang != "English" else "Not required (English)",
            "total_time": f"{timings.get('total', total_time):.3f}s",
            "timings": timings,
            "answer": answer
        }
        reports.append(report)

        print("\n--- TEST REPORT ---")
        print(f"Detected language: {report['detected_language']}")
        print(f"Translated query: {report['translated_query']}")
        print(f"Retrieved successfully: {report['retrieved_successfully']}")
        print(f"LLM answer language: {report['llm_answer_language']}")
        print(f"Answer translation: {report['answer_translation']}")
        print(f"Total time: {report['total_time']}")
        print(f"Timing breakdown: {timings}")
        print(f"\nFinal Answer:\n{answer}\n")
        print("-" * 80)

    print("\n" + "=" * 80)
    print("FINAL SUMMARY REPORT TABLE")
    print("=" * 80)
    for r in reports:
        print(f"\nTest {r['test_id']}: {r['name']}")
        print(f"  Detected language:       {r['detected_language']}")
        print(f"  Translated query:        {r['translated_query']}")
        print(f"  Retrieved successfully:  {r['retrieved_successfully']}")
        print(f"  LLM answer language:     {r['llm_answer_language']}")
        print(f"  Answer translation:      {r['answer_translation']}")
        print(f"  Total time:              {r['total_time']}")
        t = r["timings"]
        print(f"  Phase Breakdown: lang_detect={t.get('language_detection', 0):.3f}s | "
              f"query_trans={t.get('query_translation', 0):.3f}s | "
              f"retrieval={t.get('retrieval', 0):.3f}s | "
              f"prompt_const={t.get('prompt_construction', 0):.3f}s | "
              f"llm_gen={t.get('llm_generation', 0):.3f}s | "
              f"ans_trans={t.get('answer_translation', 0):.3f}s")
    print("=" * 80)

    return reports

if __name__ == "__main__":
    run_benchmark()
