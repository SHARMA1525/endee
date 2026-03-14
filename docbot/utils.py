import textwrap
from typing import List

def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
    if not text:
        return []
        
    chunks = []
    start = 0
    text_len = len(text)
    
    while start < text_len:
        end = start + chunk_size
        chunk = text[start:end]
        chunks.append(chunk)
        start += (chunk_size - overlap)
        
    return chunks

def format_context(results: List[dict]) -> str:
    context_parts = []
    for i, res in enumerate(results):
        text = res.get('text', res.get('meta', ''))
        context_parts.append(f"Source {i+1}:\n{text}")
        
    return "\n\n".join(context_parts)

if __name__ == "__main__":
    sample_text = "This is a long sentence that we want to split into smaller chunks for the RAG pipeline. " * 10
    chunks = chunk_text(sample_text, chunk_size=100, overlap=20)
    print(f"Generated {len(chunks)} chunks.")
    for i, c in enumerate(chunks[:3]):
        print(f"Chunk {i+1}: {c}")
