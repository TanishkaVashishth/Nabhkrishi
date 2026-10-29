from pathlib import Path

from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma


# ============================================================
# Paths
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
CHROMA_DIR = BASE_DIR / "chroma_db"

COLLECTION_NAME = "nabhkrishi_wheat_ipm"


# ============================================================
# 1. Find PDFs
# ============================================================

pdf_files = sorted(DATA_DIR.glob("*.pdf"))

if not pdf_files:
    raise FileNotFoundError(
        f"No PDF files found in: {DATA_DIR}"
    )

print("=" * 60)
print("NabhKrishi RAG - VECTOR STORE")
print("=" * 60)

print("\nPDF files:")

for pdf in pdf_files:
    print(" -", pdf.name)


# ============================================================
# 2. Load PDF text + metadata
# ============================================================

documents = []

for pdf_path in pdf_files:

    print("\n" + "-" * 60)
    print(f"Loading: {pdf_path.name}")
    print("-" * 60)

    loader = PyPDFLoader(str(pdf_path))
    pdf_docs = loader.load()

    print("Pages:", len(pdf_docs))


    # ========================================================
    # Dedicated Yellow Rust PDF
    # ========================================================

    if pdf_path.name == "pop_for_management_of_yellow_rust_of_wheat.pdf":

        for doc in pdf_docs:

            doc.metadata["source_file"] = pdf_path.name
            doc.metadata["crop"] = "wheat"
            doc.metadata["disease"] = "yellow_rust"
            doc.metadata["document_type"] = "IPM"

            documents.append(doc)


    # ========================================================
    # Wheat PDF - detect disease from page content
    # ========================================================

    else:

        for doc in pdf_docs:

            text = doc.page_content.lower()


            # ------------------------------------------------
            # Detect disease
            # ------------------------------------------------

            if "black rust" in text:

                disease = "black_rust"

            elif (
                "brown rust" in text
                or "leaf rust" in text
            ):

                disease = "brown_rust"

            elif (
                "yellow rust" in text
                or "stripe rust" in text
            ):

                disease = "yellow_rust"

            elif (
                "fusarium" in text
                or "head scab" in text
                or "fusarium head blight" in text
            ):

                disease = "fusarium"

            elif "powdery mildew" in text:

                disease = "powdery_mildew"

            else:

                disease = "multiple_wheat_diseases"


            # ------------------------------------------------
            # Add metadata
            # ------------------------------------------------

            doc.metadata["source_file"] = pdf_path.name
            doc.metadata["crop"] = "wheat"
            doc.metadata["disease"] = disease
            doc.metadata["document_type"] = "wheat_IPM"

            documents.append(doc)


print("\nTotal pages:", len(documents))


# ============================================================
# 3. Chunk documents
# ============================================================

print("\n" + "-" * 60)
print("Creating chunks...")
print("-" * 60)

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=150
)

chunks = text_splitter.split_documents(documents)

print("Total chunks:", len(chunks))


# ============================================================
# 4. Chunk statistics
# ============================================================

lengths = [
    len(chunk.page_content)
    for chunk in chunks
]

print(
    "Average chunk size:",
    round(sum(lengths) / len(lengths), 2)
)

print("Smallest chunk:", min(lengths))
print("Largest chunk:", max(lengths))


# ============================================================
# 5. Check metadata
# ============================================================

print("\n" + "-" * 60)
print("Checking metadata...")
print("-" * 60)

print("\nExample chunk metadata:")

print(chunks[0].metadata)


# ============================================================
# 6. Load BGE embeddings
# ============================================================

print("\n" + "-" * 60)
print("Loading BGE embedding model...")
print("-" * 60)

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
# 7. Create ChromaDB
# ============================================================

print("\n" + "-" * 60)
print("Creating ChromaDB...")
print("-" * 60)

vectorstore = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory=str(CHROMA_DIR),
    collection_name=COLLECTION_NAME
)


# ============================================================
# 8. Final information
# ============================================================

print("\n" + "=" * 60)
print("VECTOR STORE CREATED")
print("=" * 60)

print("Pages:", len(documents))
print("Chunks:", len(chunks))
print("ChromaDB:", CHROMA_DIR)
print("Collection:", COLLECTION_NAME)