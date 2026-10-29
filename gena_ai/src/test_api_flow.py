import os
import sys
import json
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

SRC_DIR = Path(__file__).resolve().parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from fastapi.testclient import TestClient
from api import app
from database import get_recent_messages, get_summary

client = TestClient(app)

def run_tests():
    print("=" * 80)
    print("NABHKRISHI CHATBOT INTEGRATION TEST - 5-QUESTION CONVERSATION FLOW")
    print("=" * 80)

    # 1. Health check
    health_resp = client.get("/health")
    print(f"\n[Health Check] Status: {health_resp.status_code}, Body: {health_resp.json()}")
    assert health_resp.status_code == 200, "Health check failed!"

    conversation_id = None

    test_questions = [
        ("Question 1 (English)", "What is yellow rust in wheat?"),
        ("Question 2 (English Follow-up)", "What are its symptoms?"),
        ("Question 3 (English Follow-up)", "How can it be managed?"),
        ("Question 4 (Hindi)", "गेहूं में पीला रतुआ क्या है?"),
        ("Question 5 (Hindi Follow-up)", "इसके लक्षण क्या हैं?")
    ]

    for step_num, (label, question) in enumerate(test_questions, start=1):
        print("\n" + "-" * 70)
        print(f"Step {step_num}: {label}")
        print(f"Farmer: {question}")
        print(f"Sending with conversation_id: {conversation_id}")
        print("-" * 70)

        payload = {
            "conversation_id": conversation_id,
            "message": question
        }

        resp = client.post("/chat", json=payload)
        print(f"Response status: {resp.status_code}")
        
        if resp.status_code != 200:
            print(f"Error details: {resp.text}")
            raise RuntimeError(f"Step {step_num} failed with status {resp.status_code}")

        data = resp.json()
        returned_conv_id = data.get("conversation_id")
        answer = data.get("answer")
        lang = data.get("language")

        print(f"\nReturned conversation_id: {returned_conv_id}")
        print(f"Detected Language: {lang}")
        print(f"\nNabhKrishi AI Answer:\n{answer}")

        # Assertions
        assert returned_conv_id is not None and len(returned_conv_id) > 0, "No conversation_id returned!"
        if conversation_id is None:
            conversation_id = returned_conv_id
        else:
            assert returned_conv_id == conversation_id, f"Conversation ID changed! Expected {conversation_id}, got {returned_conv_id}"

        assert answer is not None and len(answer.strip()) > 0, "Empty answer received!"

    # Verify Supabase persistence & summary
    print("\n" + "=" * 80)
    print("VERIFYING SUPABASE PERSISTENCE & CONVERSATION SUMMARY")
    print("=" * 80)

    messages = get_recent_messages(conversation_id, limit=20)
    print(f"Persisted messages in Supabase for conversation {conversation_id}: {len(messages)}")
    for m in messages:
        role = m.get("role")
        content = m.get("content", "")
        preview = content[:60] + ("..." if len(content) > 60 else "")
        print(f" - [{role.upper()}]: {preview}")

    summary = get_summary(conversation_id)
    print(f"\nConversation Summary in Supabase:\n{summary}")

    print("\n" + "=" * 80)
    print("ALL 5 CONVERSATION FLOW TESTS COMPLETED SUCCESSFULLY!")
    print("=" * 80)

if __name__ == "__main__":
    run_tests()
