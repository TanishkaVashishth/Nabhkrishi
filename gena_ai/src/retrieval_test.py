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
# Load BGE
# ============================================================

print("Loading BGE embedding model...")

embeddings = HuggingFaceEmbeddings(
    model_name="BAAI/bge-small-en-v1.5",
    model_kwargs={
        "device": "cpu"
    },
    encode_kwargs={
        "normalize_embeddings": True
    }
)

print("BGE loaded successfully.")


# ============================================================
# Load ChromaDB
# ============================================================

print("\nLoading ChromaDB...")

vectorstore = Chroma(
    persist_directory=str(CHROMA_DIR),
    collection_name=COLLECTION_NAME,
    embedding_function=embeddings
)

print("ChromaDB loaded successfully.")


# ============================================================
# Test question
# ============================================================

question = "What are the symptoms of yellow rust in wheat?"


print("\n" + "=" * 70)
print("QUESTION")
print("=" * 70)

print(question)


# ============================================================
# Retrieve only yellow-rust document
# ============================================================

print("\n" + "=" * 70)
print("YELLOW RUST RETRIEVAL")
print("=" * 70)

results = vectorstore.similarity_search_with_score(
    question,
    k=5,
    filter={
        "disease": "yellow_rust"
    }
)


# ============================================================
# Display results
# ============================================================

for i, (doc, score) in enumerate(results, start=1):

    print("\n" + "-" * 70)
    print(f"RESULT {i}")
    print("-" * 70)

    print("Distance:", score)

    print("\nSource:")
    print(doc.metadata.get("source_file"))

    print("Disease:")
    print(doc.metadata.get("disease"))

    print("Document type:")
    print(doc.metadata.get("document_type"))

    print("Page:")
    print(doc.metadata.get("page"))

    print("\nContent:")
    print(doc.page_content[:1500])