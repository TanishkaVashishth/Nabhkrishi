from pathlib import Path

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma


# ============================================================
# Paths
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

CHROMA_DIR = BASE_DIR / "chroma_db"

COLLECTION_NAME = "nabhkrishi_wheat_ipm"


# ============================================================
# 1. Load embedding model
# ============================================================

embeddings = HuggingFaceEmbeddings(
    model_name="BAAI/bge-small-en-v1.5",
    model_kwargs={
        "device": "cpu"
    },
    encode_kwargs={
        "normalize_embeddings": True
    }
)


# ============================================================
# 2. Load ChromaDB
# ============================================================

vectorstore = Chroma(
    persist_directory=str(CHROMA_DIR),
    collection_name=COLLECTION_NAME,
    embedding_function=embeddings
)


# ============================================================
# 3. Disease aliases (English, Hindi, Punjabi, Bengali, Haryanvi)
# ============================================================

DISEASE_ALIASES = {
    "yellow_rust": [
        "yellow rust",
        "stripe rust",
        "yellow stripe rust",
        "पीला रतुआ",
        "peela ratua",
        "pila ratua",
        "ਪੀਲਾ ਰਤੂਆ",
        "ਪੀਲੀ ਕੁੰਗੀ",
        "ਕੁੰਗੀ",
        "peeli kungi",
        "হলুদ মরিচা",
        "হলদে মরিচা",
    ],
    "black_rust": [
        "black rust",
        "stem rust",
        "काला रतुआ",
        "kala ratua",
        "ਕਾਲਾ ਰਤੂਆ",
        "ਕਾਲੀ ਕੁੰਗੀ",
        "কালো মরিচা",
    ],
    "brown_rust": [
        "brown rust",
        "leaf rust",
        "भूरा रतुआ",
        "bhura ratua",
        "ਭੂਰਾ ਰਤੂਆ",
        "ਭੂਰੀ ਕੁੰਗੀ",
        "বাদামী মরিচা",
    ],
    "powdery_mildew": [
        "powdery mildew",
        "mildew",
        "चूर्णी फफूंद",
        "churna",
        "ਚਿੱਟਾ ਰੋਗ",
        "ਪਾਊਡਰੀ ਫ਼ਫ਼ੂੰਦੀ",
        "পাউডারি মিলডিউ",
    ],
    "fusarium": [
        "fusarium",
        "fusarium head blight",
        "head scab",
        "fusarium head scab",
        "हेड ब्लाइट",
    ],
    "karnal_bunt": [
        "karnal bunt",
        "कर्नाल बंट",
        "ਕਰਨਾਲ ਬੰਟ",
        "bunt",
    ],
    "loose_smut": [
        "loose smut",
        "smut",
        "कंडुआ",
        "कंगुआ",
        "kangua",
        "kandua",
        "ਕਾਂਗਿਆਰੀ",
        "ਕੰਗੂਆ",
        "আলগা স্মাট",
        "স্মাট",
    ],
    "root_rot": [
        "root rot",
        "common root rot",
        "जड़ सड़न",
        "ਜੜ੍ਹ ਗਲਣ",
        "শিকড় পচা",
    ],
    "aphid": [
        "aphid",
        "aphids",
        "माहू",
        "चेपा",
        "mahu",
        "chepa",
        "ਤੇਲਾ",
        "ਚੇਪਾ",
        "জাব পোকা",
        "এফিড",
    ],
    "termite": [
        "termite",
        "termites",
        "दीमक",
        "deemak",
        "ਸਿਉਂਕ",
        "উইপোকা",
    ],
    "blast": [
        "blast",
        "wheat blast",
        "ब्लास्ट",
        "ব্লাস্ট",
        "গম ব্লাস্ট",
    ],
    "leaf_blight": [
        "leaf blight",
        "झुलसा",
        "पत्ती झुलसा",
        "ਬਲਾਈਟ",
        "ব্লাইট",
        "পাতা পোড়া",
    ],
    "mite": [
        "mite",
        "mites",
        "माइट",
        "ਮਾਈਟ",
    ],
    "tan_spot": [
        "tan spot",
        "टैन स्पॉट",
    ],
    "septoria": [
        "septoria",
        "सेप्टोरिया",
    ],
}


# ============================================================
# 4. Topic keywords (English, Hindi, Punjabi, Bengali, Haryanvi)
# ============================================================

TOPIC_KEYWORDS = {
    "symptoms": [
        "symptom",
        "symptoms",
        "sign",
        "signs",
        "look like",
        "identify",
        "identification",
        "appearance",
        "लक्षण",
        "lakshan",
        "पहचान",
        "ਲੱਛਣ",
        "ਪਛਾਣ",
        "লক্ষণ",
        "শনাক্তকরণ",
    ],
    "management": [
        "manage",
        "management",
        "control",
        "treatment",
        "treat",
        "what should i do",
        "what can i do",
        "spray",
        "dose",
        "dosage",
        "रोकथाम",
        "इलाज",
        "उपचार",
        "दवा",
        "स्प्रे",
        "roktham",
        "ilaj",
        "upchar",
        "dawa",
        "ਰੋਕਥਾਮ",
        "ਇਲਾਜ",
        "ਦਵਾਈ",
        "ਸਪਰੇਅ",
        "দমন",
        "প্রতিকার",
        "ওষুধ",
        "স্প্রে",
    ],
    "spread": [
        "spread",
        "spreads",
        "transmit",
        "transmission",
        "dissemination",
        "how does it spread",
        "फैलाव",
        "failta",
        "ਫੈਲਾਅ",
        "বিস্তার",
    ],
    "favourable_conditions": [
        "favourable conditions",
        "favorable conditions",
        "weather",
        "temperature",
        "humidity",
        "conditions",
        "climate",
        "मौसम",
        "तापमान",
        "अनुकूल",
        "ਮੌਸਮ",
        "আবহাওয়া",
    ],
    "survival": [
        "survive",
        "survival",
        "survives",
        "source of infection",
        "where does it survive",
    ],
    "prevention": [
        "prevent",
        "prevention",
        "avoid",
        "protect",
        "protection",
        "बचाव",
        "suraksha",
        "ਬਚਾਅ",
        "প্রতিরোধ",
    ],
}


# ============================================================
# In-memory LRU retrieval cache (avoids repeated embedding calls)
# ============================================================

_RETRIEVAL_CACHE = {}
_MAX_CACHE_SIZE = 256


# ============================================================
# 5. Detect disease
# ============================================================

def detect_disease(question):

    question_lower = question.lower()

    for disease, aliases in DISEASE_ALIASES.items():

        for alias in aliases:

            if alias in question_lower:
                return disease

    return None


# ============================================================
# 6. Detect topics
# ============================================================

def detect_topics(question):

    question_lower = question.lower()

    detected_topics = []

    for topic, keywords in TOPIC_KEYWORDS.items():

        for keyword in keywords:

            if keyword in question_lower:

                detected_topics.append(topic)

                break

    # If no specific topic was detected
    if not detected_topics:
        detected_topics.append("general")

    return detected_topics


# ============================================================
# 7. Topic search terms
# ============================================================

TOPIC_SEARCH_TERMS = {

    "symptoms":
        "symptoms signs disease appearance lesions pustules",

    "management":
        "management control treatment prevention IPM practices",

    "spread":
        "spread transmission spores infection",

    "favourable_conditions":
        "favourable conditions temperature humidity weather infection",

    "survival":
        "survival source inoculum crop debris seed soil",

    "prevention":
        "prevention management IPM resistant varieties sanitation",

    "general":
        ""
}


# ============================================================
# 8. Check useful chunk
# ============================================================

def is_useful_chunk(doc):

    text = doc.page_content.lower().strip()

    if len(text) < 150:
        return False

    if "table of contents" in text:
        return False

    if text.startswith("http://"):
        return False

    if text.startswith("https://"):
        return False

    if "google.co.in/search?q=" in text:
        return False

    return True


# ============================================================
# 9. Build focused query
# ============================================================

def build_topic_query(question, disease, topic):

    topic_terms = TOPIC_SEARCH_TERMS.get(
        topic,
        ""
    )

    if disease:
        disease_name = disease.replace(
            "_",
            " "
        )
        return (
            f"{question} "
            f"{disease_name} "
            f"wheat "
            f"{topic_terms}"
        )

    return (
        f"{question} "
        f"wheat "
        f"{topic_terms}"
    )


# ============================================================
# 10. Retrieve documents
# ============================================================

def retrieve_documents(question, k=3):
    cache_key = (question.strip().lower(), k)
    if cache_key in _RETRIEVAL_CACHE:
        return _RETRIEVAL_CACHE[cache_key]

    disease = detect_disease(question)
    topics = detect_topics(question)
    all_results = {}

    # Limit to top 2 detected topics to avoid redundant sequential vector queries
    active_topics = topics[:2] if len(topics) > 2 else topics
    fetch_k = max(k, 3)

    for topic in active_topics:
        search_query = build_topic_query(
            question,
            disease,
            topic
        )

        # Disease-aware search
        if disease:
            try:
                results = vectorstore.similarity_search_with_score(
                    search_query,
                    k=fetch_k,
                    filter={
                        "disease": disease
                    }
                )
            except Exception:
                results = []

            # Fallback to general search if filtered search returned no matches
            if not results:
                results = vectorstore.similarity_search_with_score(
                    search_query,
                    k=fetch_k
                )
        else:
            results = vectorstore.similarity_search_with_score(
                search_query,
                k=fetch_k
            )

        # Store useful results
        for doc, score in results:
            if not is_useful_chunk(doc):
                continue

            key = (
                doc.metadata.get("source_file", ""),
                doc.metadata.get("page", ""),
                doc.page_content[:100]
            )

            if key not in all_results or score < all_results[key][1]:
                all_results[key] = (doc, score)

    final_results = sorted(
        all_results.values(),
        key=lambda x: x[1]
    )[:k]

    # Save to memory cache with eviction
    if len(_RETRIEVAL_CACHE) >= _MAX_CACHE_SIZE:
        # Evict oldest 50 items
        for old_k in list(_RETRIEVAL_CACHE.keys())[:50]:
            _RETRIEVAL_CACHE.pop(old_k, None)
    _RETRIEVAL_CACHE[cache_key] = final_results

    return final_results