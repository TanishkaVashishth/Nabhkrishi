from pathlib import Path

from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter


# ============================================================
# Paths
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = BASE_DIR / "data"


# ============================================================
# Find PDF files
# ============================================================

pdf_files = list(DATA_DIR.glob("*.pdf"))

print("=" * 60)
print("NabhKrishi RAG - PDF INGESTION")
print("=" * 60)

print("\nData directory:")
print(DATA_DIR)

print("\nPDF files found:")

for pdf in pdf_files:
    print(" -", pdf.name)


if not pdf_files:
    raise FileNotFoundError(
        f"No PDF files found in {DATA_DIR}"
    )


# ============================================================
# Load PDFs
# ============================================================

documents = []

for pdf_path in pdf_files:

    print("\n" + "-" * 60)
    print("Loading:", pdf_path.name)
    print("-" * 60)

    loader = PyPDFLoader(str(pdf_path))

    pdf_documents = loader.load()

    print("Pages loaded:", len(pdf_documents))

    documents.extend(pdf_documents)


# ============================================================
# Basic extraction check
# ============================================================

print("\n" + "=" * 60)
print("TEXT EXTRACTION CHECK")
print("=" * 60)

print("Total pages:", len(documents))

total_characters = sum(
    len(doc.page_content)
    for doc in documents
)

print("Total extracted characters:", total_characters)


# Show first page
if documents:

    print("\n" + "-" * 60)
    print("FIRST PAGE TEXT")
    print("-" * 60)

    print(documents[0].page_content[:3000])


# ============================================================
# Split text into chunks
# ============================================================

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=150,
)

chunks = text_splitter.split_documents(documents)


# ============================================================
# Chunk statistics
# ============================================================

print("\n" + "=" * 60)
print("CHUNKING COMPLETE")
print("=" * 60)

print("Total chunks:", len(chunks))

if chunks:

    chunk_lengths = [
        len(chunk.page_content)
        for chunk in chunks
    ]

    print(
        "Average chunk size:",
        round(sum(chunk_lengths) / len(chunk_lengths), 2)
    )

    print(
        "Smallest chunk:",
        min(chunk_lengths)
    )

    print(
        "Largest chunk:",
        max(chunk_lengths)
    )


# ============================================================
# Show sample chunks
# ============================================================

print("\n" + "=" * 60)
print("SAMPLE CHUNKS")
print("=" * 60)

for i, chunk in enumerate(chunks[:3]):

    print("\n" + "-" * 60)
    print(f"CHUNK {i + 1}")
    print("-" * 60)

    print(chunk.page_content[:1500])

    print("\nMetadata:")
    print(chunk.metadata)
    print("\n" + "=" * 60)
print("CHUNK QUALITY CHECK")
print("=" * 60)

for i, chunk in enumerate(chunks[:10]):
    print(f"\nCHUNK {i + 1}")
    print("-" * 60)
    print(chunk.page_content)
    print("\nMetadata:", chunk.metadata)