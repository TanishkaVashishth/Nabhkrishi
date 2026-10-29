import os
from dotenv import load_dotenv
from openai import OpenAI

# ---------------------------------------------------------
# Load environment variables
# ---------------------------------------------------------

load_dotenv()

NVIDIA_API_KEY = os.getenv("NVIDIA_API_KEY")
NVIDIA_MODEL = os.getenv(
    "NVIDIA_MODEL",
    "nvidia/nemotron-3-ultra-550b-a55b"
)

if not NVIDIA_API_KEY:
    raise ValueError(
        "NVIDIA_API_KEY is missing from your .env file"
    )

# ---------------------------------------------------------
# NVIDIA OpenAI-compatible client
# ---------------------------------------------------------

client = OpenAI(
    base_url="https://integrate.api.nvidia.com/v1",
    api_key=NVIDIA_API_KEY
)

print("Connecting to NVIDIA...")
print("Model:", NVIDIA_MODEL)

# ---------------------------------------------------------
# System prompt for our agricultural RAG assistant
# ---------------------------------------------------------

system_prompt = """
You are NabhKrishi AI, an agricultural assistant for wheat farmers.

Your job is to:
- explain wheat diseases in simple language,
- provide farmer-friendly Integrated Pest Management (IPM) guidance,
- avoid inventing pesticide recommendations,
- recommend expert or extension support when diagnosis is uncertain,
- give concise and practical answers.

For now this is a model connectivity test, so answer using your
general knowledge. Later, answers will be grounded in retrieved
government IPM documents.
"""

# ---------------------------------------------------------
# Test question
# ---------------------------------------------------------

question = """
What is yellow rust in wheat?
Explain the main symptoms and what a farmer should do.
"""

# ---------------------------------------------------------
# Call Nemotron-3-Ultra
# ---------------------------------------------------------

response = client.chat.completions.create(
    model=NVIDIA_MODEL,

    messages=[
        {
            "role": "system",
            "content": system_prompt
        },
        {
            "role": "user",
            "content": question
        }
    ],

    # NVIDIA's recommended sampling values for this model
    temperature=1.0,
    top_p=0.95,

    # 1000 is enough for our chatbot test.
    # NVIDIA supports a much larger output budget.
    max_tokens=1000,

    extra_body={
        "chat_template_kwargs": {
            "enable_thinking": False
        }
    },

    stream=False
)

# ---------------------------------------------------------
# Print result
# ---------------------------------------------------------

answer = response.choices[0].message.content

print("\n" + "=" * 60)
print("NVIDIA NEMOTRON RESPONSE")
print("=" * 60)
print(answer)

print("\nFinish reason:")
print(response.choices[0].finish_reason)