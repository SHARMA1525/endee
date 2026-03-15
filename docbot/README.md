# DocBot – AI Document Assistant using Endee & Ollama

**DocBot** is a clean, recruiter-friendly RAG (Retrieval Augmented Generation) assistant designed to showcase the power of the **Endee Vector Database** combined with local LLMs. It allows users to upload PDF documents, index them using state-of-the-art embeddings, and ask questions through a simple interface—running completely offline.

## 🚀 Problem Statement
Traditional cloud-based RAG systems often require expensive API keys and compromise data privacy. DocBot overcomes these limitations by using **Endee** for sub-millisecond local vector search and **Ollama** for local AI inference, keeping all data on your machine.

## 🏗️ System Architecture

1. **Document Ingestion**: PDFs are loaded and split into overlapping text chunks.
2. **Embedding Generation**: Each chunk is converted into a vector using the `all-MiniLM-L6-v2` Sentence Transformer.
3. **Vector Storage**: Embeddings and original text are stored in the **Endee Vector Database**.
4. **Retrieval**: User questions are embedded, and Endee performs a lightning-fast similarity search to find relevant context.
5. **Local RAG Pipeline**: The retrieved chunks are provided as context to **Ollama (Llama3)** to generate a grounded, accurate answer locally.

```text
User Question → [Embedding] → Endee Search → [Context Chunks] → Ollama (Llama3) → [AI Answer]
```

## 🛠️ Tech Stack

* **Endee**: High-performance open-source vector database.
* **Ollama**: Local LLM execution engine for running `llama3`.
* **Python**: Primary logic and pipeline.
* **Streamlit**: Modern and interactive web UI.
* **Sentence Transformers**: Local embedding generation.
* **PyPDF2**: Robust PDF text extraction.

## 📦 Project Structure

```text
docbot/
├── app.py             # Streamlit UI
├── ingest.py          # PDF processing and Endee indexing
├── embeddings.py      # Embedding generation helper
├── rag_pipeline.py    # Search and Ollama logic
├── utils.py           # Text chunking and formatting utilities
├── requirements.txt   # Project dependencies
└── README.md          # Documentation
```

## ⚙️ Setup Instructions

### 1. Prerequisites
* Python 3.9+ installed.
* **Endee** running locally (port `8080`).
* **Ollama** installed and running.
  * Download from: [ollama.com](https://ollama.com/)
  * Run the model: `ollama run llama3`

### 2. Install Dependencies
```bash
cd docbot
pip install -r requirements.txt
```

### 3. Run the App
```bash
streamlit run app.py
```

## 🌐 Public Deployment (Hosting)
If you want to host DocBot publicly while keeping your data local, you need a tunnel for **both** Endee (8080) and Ollama (11434).

### Option A: Localtunnel (Recommended for Free Users)
Localtunnel allows you to run multiple tunnels for free:
1. **Expose Services**:
   ```bash
   chmod +x ./docbot/expose_services_lt.sh
   ./docbot/expose_services_lt.sh
   ```
2. **Configure App**: Copy the generated URLs into your DocBot sidebar.

### Option B: ngrok
Best if you have a paid ngrok plan or a static domain:
1. **Expose Services**:
   ```bash
   # Note: Free plan might be limited to 1 tunnel
   ./docbot/expose_services.sh
   ```

## ✨ Integration with Endee
DocBot utilizes Endee's HTTP API for:
* **Schema Management**: Auto-creating indexes with optimized precision (`int16`).
* **Batch Insertion**: Efficiently uploading vectors and metadata chunks.
* **Similarity Search**: Leveraging Endee's HNSW backend for sub-millisecond retrieval.
* **Local Persistence**: Ensuring document data remains on-site and queryable.

---
*Created as a demonstration of high-performance local search and RAG architecture.*
