import os
import requests
import json
from PyPDF2 import PdfReader
from embeddings import get_embeddings_batch
from utils import chunk_text
from typing import List
ENDEE_URL = os.getenv("ENDEE_URL", "http://localhost:8080")
ENDEE_AUTH_TOKEN = os.getenv("ENDEE_AUTH_TOKEN", "")
INDEX_NAME = "docbot_index"
USERNAME = "endee"

def create_index_if_not_exists(dim: int):
    headers = {}
    if ENDEE_AUTH_TOKEN:
        headers["Authorization"] = ENDEE_AUTH_TOKEN
    
    try:
        response = requests.get(f"{ENDEE_URL}/api/v1/index/list", headers=headers)
        if response.status_code == 200:
            indexes = response.json().get("indexes", [])
            if any(idx["name"] == INDEX_NAME for idx in indexes):
                print(f"Index '{INDEX_NAME}' already exists.")
                return
    except Exception as e:
        print(f"Error checking index list: {e}")
    payload = {
        "index_name": INDEX_NAME,
        "dim": dim,
        "space_type": "cosine",
        "precision": "int16"
    }
    
    try:
        response = requests.post(f"{ENDEE_URL}/api/v1/index/create", json=payload, headers=headers)
        if response.status_code == 200:
            print(f"Successfully created index '{INDEX_NAME}'.")
        else:
            print(f"Failed to create index: {response.text}")
    except Exception as e:
        print(f"Error creating index: {e}")

def index_documents(chunks: List[str]):
    if not chunks:
        return
        
    print(f"Generating embeddings for {len(chunks)} chunks...")
    embeddings = get_embeddings_batch(chunks)
    
    vectors = []
    for i, (chunk, vector) in enumerate(zip(chunks, embeddings)):
        vectors.append({
            "id": f"chunk_{i}_{hash(chunk)}",
            "vector": vector,
            "meta": chunk
        })
    
    headers = {"Content-Type": "application/json"}
    if ENDEE_AUTH_TOKEN:
        headers["Authorization"] = ENDEE_AUTH_TOKEN

    # Batch inserts for better performance and reliability
    batch_size = 256
    for i in range(0, len(vectors), batch_size):
        batch = vectors[i : i + batch_size]
        try:
            print(f"Indexing batch {i//batch_size + 1}/{(len(vectors)-1)//batch_size + 1}...")
            response = requests.post(
                f"{ENDEE_URL}/api/v1/index/{INDEX_NAME}/vector/insert",
                json=batch,
                headers=headers
            )
            if response.status_code != 200:
                print(f"Failed to insert batch: {response.text}")
        except Exception as e:
            print(f"Error indexing batch: {e}")
    
    print(f"Finished indexing {len(vectors)} chunks.")

def process_pdf(pdf_path: str) -> List[str]:
    try:
        reader = PdfReader(pdf_path)
        text = ""
        for page in reader.pages:
            content = page.extract_text()
            if content:
                text += content + "\n"
        return text
    except Exception as e:
        print(f"Error reading PDF {pdf_path}: {e}")
        return ""

def run_ingestion(pdf_path: str):
    print(f"Processing: {pdf_path}")
    text = process_pdf(pdf_path)
    if not text:
        print("No text extracted from PDF.")
        return
        
    chunks = chunk_text(text)
    print(f"Split document into {len(chunks)} chunks.")
    from embeddings import get_embeddings
    sample_vector = get_embeddings("test")
    dim = len(sample_vector)
    
    create_index_if_not_exists(dim)
    index_documents(chunks)

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        run_ingestion(sys.argv[1])
    else:
        print("Please provide a PDF file path.")
