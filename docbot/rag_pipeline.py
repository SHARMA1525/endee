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

def get_ollama_client():
    host = os.getenv("OLLAMA_HOST", "http://127.0.0.1:11434")
    # Add multiple headers for ngrok and localtunnel public access bypass
    headers = {
        "ngrok-skip-browser-warning": "true",
        "Bypass-Tunnel-Reminder": "true",
        "bypass-tunnel-reminder": "true",
        "User-Agent": "Bypassing-Localtunnel-Reminder"
    }
    # Ensure no trailing slash for the client host
    host = host.rstrip('/')
    return ollama.Client(host=host, headers=headers)

def search_top_k(query: str, k: int = 3) -> List[dict]:
    vector = get_embeddings(query)
    
    payload = {
        "vector": vector,
        "k": k
    }
    
    headers = {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
        "Bypass-Tunnel-Reminder": "true",
        "bypass-tunnel-reminder": "true",
        "User-Agent": "Bypassing-Localtunnel-Reminder"
    }
    if ENDEE_AUTH_TOKEN:
        headers["Authorization"] = ENDEE_AUTH_TOKEN
        
    # Support unified proxy paths by joining correctly
    base_url = ENDEE_URL.rstrip('/')
    search_endpoint = f"{base_url}/api/v1/index/{INDEX_NAME}/search"
    
    try:
        response = requests.post(
            search_endpoint,
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
            return {"error": f"Search failed (Status {response.status_code}): {response.text}"}
    except requests.exceptions.ConnectionError:
        return {"error": "Could not connect to Endee server. Please check your Endee URL/Tunnel."}
    except Exception as e:
        return {"error": f"Search error: {e}"}

def generate_answer(question: str, context: str, stream: bool = False):
    prompt = f"""
    Use the following Context to answer the Question. If the context is empty, answer based on your general knowledge but mention that no specific documents were found.

    Context:
    {context}

    Question:
    {question}

    Answer:
    """

    try:
        model = os.getenv("OLLAMA_MODEL", "llama3:latest")
        client = get_ollama_client()
        
        if stream:
            return client.chat(
                model=model,
                messages=[
                    {"role": "assistant", "content": "You are a helpful AI assistant called DocBot."},
                    {"role": "user", "content": prompt}
                ],
                stream=True
            )
        else:
            response = client.chat(
                model=model,
                messages=[
                    {"role": "assistant", "content": "You are a helpful AI assistant called DocBot."},
                    {"role": "user", "content": prompt}
                ]
            )
            return response["message"]["content"]
    except Exception as e:
        model = os.getenv("OLLAMA_MODEL", "llama3:latest")
        host = os.getenv("OLLAMA_HOST", "http://127.0.0.1:11434")
        return f"Error connecting to Ollama: {e}. [Host: {host}] [Model: {model}]. Please ensure Ollama is running and the model is pulled."

def rag_query(query: str, stream: bool = False) -> dict:
    search_results = search_top_k(query)
    
    # Check if we got an error dictionary instead of a list
    if isinstance(search_results, dict) and "error" in search_results:
        error_msg = search_results["error"]
        results = []
        context = ""
    else:
        error_msg = None
        results = search_results
        context = format_context(results)
    
    answer = generate_answer(query, context, stream=stream)
    
    return {
        "answer": answer,
        "context": results,
        "error": error_msg
    }

if __name__ == "__main__":
    q = "What is machine learning?"
    print(f"Query: {q}")
    response = rag_query(q)
    print(f"Answer: {response['answer']}")
