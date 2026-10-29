from langchain_huggingface import HuggingFaceEmbeddings

print("Loading embedding model...")

embeddings = HuggingFaceEmbeddings(
    model_name="BAAI/bge-small-en-v1.5"
)

text = "Yellow rust is a disease of wheat."

vector = embeddings.embed_query(text)

print("Embedding successful!")
print("Vector dimension:", len(vector))
print("First 10 values:", vector[:10])