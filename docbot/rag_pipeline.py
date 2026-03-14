import os
import requests
import msgpack
import ollama
from embeddings import get_embeddings
from utils import format_context
from typing import List

ENDEE_URL = os.getenv("ENDEE_URL", "http://localhost:8080")
ENDEE_AUTH_TOKEN = os.getenv("ENDEE_AUTH_TOKEN", "")
INDEX_NAME = "docbot_index"
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")

def search_top_k(query: str, k: int = 3) -> List[dict]:
    vector = get_embeddings(query)
    
    payload = {
        "vector": vector,
        "k": k
    }
    
    headers = {"Content-Type": "application/json"}
    if ENDEE_AUTH_TOKEN:
        headers["Authorization"] = ENDEE_AUTH_TOKEN
        
    try:
        response = requests.post(
            f"{ENDEE_URL}/api/v1/index/{INDEX_NAME}/search",
            json=payload,
            headers=headers
        )
        
        if response.status_code == 200:
            results = msgpack.unpackb(response.content, raw=False)
            
            formatted_results = []
            for res in results:
                if isinstance(res, (list, tuple)) and len(res) >= 3:
                    similarity = res[0]
                    res_id = res[1]
                    meta_bytes = res[2]
                    if isinstance(meta_bytes, bytes):
                        text = meta_bytes.decode('utf-8', errors='ignore')
                    else:
                        text = str(meta_bytes)
                        
                    formatted_results.append({
                        "id": res_id,
                        "score": similarity,
                        "text": text
                    })
            return formatted_results
        else:
            print(f"Search failed with status {response.status_code}: {response.text}")
            return []
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to Endee server. Is it running?")
        return []
    except Exception as e:
        print(f"Error during search: {e}")
        return []

def generate_answer(question: str, context: str) -> str:
    prompt = f"""

    Context:
    {context}

    Question:
    {question}

    Answer:
    """

    try:
        response = ollama.chat(
            model=OLLAMA_MODEL,
            messages=[
                {"role": "assistant", "content": "You are a helpful AI assistant called DocBot."},
                {"role": "user", "content": prompt}
            ]
        )
        return response["message"]["content"]
    except Exception as e:
        return f"Error connecting to Ollama: {e}. Ensure Ollama is running (`ollama run {OLLAMA_MODEL}`)."

def rag_query(query: str) -> dict:
    results = search_top_k(query)
    context = format_context(results)
    answer = generate_answer(query, context)
    
    return {
        "answer": answer,
        "context": results
    }

if __name__ == "__main__":
    q = "What is machine learning?"
    print(f"Query: {q}")
    response = rag_query(q)
    print(f"Answer: {response['answer']}")
