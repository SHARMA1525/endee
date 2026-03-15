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
If you want to host DocBot (e.g., on Streamlit Cloud) while keeping your data and LLM local, use the provided **ngrok** helper script:

1. **Install ngrok**: Follow [ngrok.com](https://ngrok.com/download).
2. **Expose Services**:
   ```bash
   ./expose_services.sh
   ```
3. **Configure App**: Copy the generated public URLs from your terminal and paste them into the "Endee URL" and "Ollama Host" fields in the DocBot sidebar.

## ✨ Integration with Endee
DocBot utilizes Endee's HTTP API for:
* **Schema Management**: Auto-creating indexes with optimized precision (`int16`).
* **Batch Insertion**: Efficiently uploading vectors and metadata chunks.
* **Similarity Search**: Leveraging Endee's HNSW backend for sub-millisecond retrieval.
* **Local Persistence**: Ensuring document data remains on-site and queryable.

---
*Created as a demonstration of high-performance local search and RAG architecture.*
