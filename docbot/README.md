# DocBot – AI Document Assistant using Endee & Ollama

**DocBot** is a clean, recruiter-friendly RAG (Retrieval Augmented Generation) assistant designed to showcase the power of the **Endee Vector Database** combined with local LLMs. It allows users to upload PDF documents, index them using state-of-the-art embeddings, and ask questions through a simple interface—running completely offline.

## 🚀 Problem Statement
Traditional cloud-based RAG systems often require expensive API keys and compromise data privacy. DocBot overcomes these limitations by using **Endee** for sub-millisecond local vector search and **Ollama** for local AI inference, keeping all data on your machine.

## 🏗️ System Architecture

1. **Document Ingestion**: PDFs are loaded and split into overlapping text chunks.
