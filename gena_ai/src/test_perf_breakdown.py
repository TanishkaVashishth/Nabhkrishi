import sys
import time
from pathlib import Path

SRC_DIR = Path(__file__).resolve().parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from chatbot import detect_language
from retriever import retrieve_documents
import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

print("--- 1. Testing detect_language ---")
t0 = time.perf_counter()
lang = detect_language("गेहूं में पीला रतुआ क्या है?")
print(f"Detected: {lang} in {time.perf_counter() - t0:.6f}s")

print("\n--- 2. Testing retrieve_documents ---")
t0 = time.perf_counter()
docs = retrieve_documents("yellow rust", k=2)
print(f"Retrieved {len(docs)} docs in {time.perf_counter() - t0:.4f}s")

print("\n--- 3. Testing NVIDIA Nemotron API ---")
client = OpenAI(base_url="https://integrate.api.nvidia.com/v1", api_key=os.getenv("NVIDIA_API_KEY"))
model = os.getenv("NVIDIA_MODEL", "nvidia/nemotron-3-ultra-550b-a55b")

t0 = time.perf_counter()
try:
    resp = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": "Say hello in 3 words"}],
        max_tokens=20,
        temperature=0.2,
        extra_body={"chat_template_kwargs": {"enable_thinking": False}},
        timeout=15.0
    )
    print(f"Nemotron responded in {time.perf_counter() - t0:.3f}s: {resp.choices[0].message.content}")
except Exception as e:
    print(f"Nemotron error after {time.perf_counter() - t0:.3f}s: {type(e)} - {e}")
