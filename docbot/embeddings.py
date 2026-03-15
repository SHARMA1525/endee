import torch
from sentence_transformers import SentenceTransformer
from typing import List

MODEL_NAME = 'all-MiniLM-L6-v2'

_model = None

def get_model():
    global _model
    if _model is None:
        if torch.backends.mps.is_available():
            device = 'mps'
        elif torch.cuda.is_available():
            device = 'cuda'
        else:
            device = 'cpu'
        print(f"Loading embedding model on device: {device}")
        _model = SentenceTransformer(MODEL_NAME, device=device)
    return _model

def get_embeddings(text: str) -> List[float]:
    model = get_model()
    embedding = model.encode(text, convert_to_tensor=False)
    return embedding.tolist()

def get_embeddings_batch(texts: List[str]) -> List[List[float]]:
    if not texts:
        return []
    model = get_model()
    embeddings = model.encode(texts, convert_to_tensor=False)
    return embeddings.tolist()

if __name__ == "__main__":
    test_text = "Endee is a high-performance vector database."
    vector = get_embeddings(test_text)
    print(f"Embedding dimension: {len(vector)}")
    print(f"First 5 values: {vector[:5]}")
