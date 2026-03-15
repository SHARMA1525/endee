import streamlit as st
import os
import tempfile
from ingest import run_ingestion
from rag_pipeline import rag_query
from dotenv import load_dotenv
load_dotenv()

st.set_page_config(
    page_title="DocBot - AI Document Assistant",
    page_icon="🤖",
    layout="wide"
)


st.markdown("""
<style>
    .main {
        background-color: #f5f7f9;
    }
    .stButton>button {
        width: 100%;
        border-radius: 5px;
        height: 3em;
        background-color: #4CAF50;
        color: white;
    }
    .stTextInput>div>div>input {
        border-radius: 5px;
    }
    .result-card {
        background-color: #1e1e1e;
        color: #ffffff;
        padding: 20px;
        border-radius: 10px;
        border-left: 5px solid #4CAF50;
        margin-bottom: 20px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.3);
    }
    .chunk-card {
        background-color: #2b2b2b;
        color: #e0e0e0;
        padding: 15px;
        border-radius: 8px;
        border: 1px solid #444;
        margin-bottom: 10px;
        font-size: 0.9em;
    }
</style>
""", unsafe_allow_html=True)

with st.sidebar:
    st.title("Configuration")
    st.markdown("---")
    
    if "endee_url" not in st.session_state:
        st.session_state.endee_url = os.getenv("ENDEE_URL", "http://localhost:8080")
    if "auth_token" not in st.session_state:
        st.session_state.auth_token = os.getenv("ENDEE_AUTH_TOKEN", "")
    if "ollama_model" not in st.session_state:
        st.session_state.ollama_model = os.getenv("OLLAMA_MODEL", "llama3:latest")
    if "ollama_host" not in st.session_state:
        st.session_state.ollama_host = os.getenv("OLLAMA_HOST", "http://127.0.0.1:11434")

    st.session_state.endee_url = st.text_input("Endee URL", value=st.session_state.endee_url, help="Local (http://localhost:8080) or Public ngrok URL")
    st.session_state.auth_token = st.text_input("Auth Token (Optional)", value=st.session_state.auth_token, type="password", help="Endee Auth Token if enabled")
    st.session_state.ollama_model = st.text_input("Ollama Model", value=st.session_state.ollama_model, help="e.g., llama3:latest")
    st.session_state.ollama_host = st.text_input("Ollama Host", value=st.session_state.ollama_host, help="Local (http://localhost:11434) or Public ngrok URL")
    
    os.environ["ENDEE_URL"] = st.session_state.endee_url
    os.environ["ENDEE_AUTH_TOKEN"] = st.session_state.auth_token
    os.environ["OLLAMA_MODEL"] = st.session_state.ollama_model
    os.environ["OLLAMA_HOST"] = st.session_state.ollama_host


    if st.button("Update Configuration"):
        st.success("Configuration updated! If the website is hosted, ensure the URLs are public (e.g., ngrok).")

st.title("🤖 DocBot – AI Document Assistant")
st.markdown("""
Welcome to **DocBot**! This assistant uses the **Endee Vector Database** for semantic search and **Ollama (Llama3)** for offline AI answers.
""")

st.markdown("---")

col1, col2 = st.columns([1, 1])

with col1:
    st.header("Upload Document")
    uploaded_file = st.file_uploader("Choose a PDF file", type="pdf")
    
    if uploaded_file is not None:
        if st.button("Process & Index Document"):
            with st.spinner("Processing PDF and indexing in Endee..."):
                with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
                    tmp_file.write(uploaded_file.getvalue())
                    tmp_path = tmp_file.name
                
                try:
                    run_ingestion(tmp_path)
                    st.success(f"Successfully indexed '{uploaded_file.name}'!")
                except Exception as e:
                    st.error(f"Error during ingestion: {e}")
                finally:
                    os.remove(tmp_path)

with col2:
    st.header("Ask a Question")
    user_query = st.text_input("What would you like to know about the documents?")
    
    if user_query:
        if st.button("Get Answer"):
            # Silent search and generation

            with st.spinner("Searching and generating answer..."):
                response = rag_query(user_query, stream=True)
                
                # Silent error handling (logs to console, hides from UI)
                if response.get("error"):
                    print(f"DEBUG: Search failed: {response['error']}")
                
                st.markdown("### AI Answer")
                
                # Stream the response
                def stream_data():
                    for chunk in response["answer"]:
                        content = chunk.get("message", {}).get("content", "")
                        yield content
                
                st.write_stream(stream_data)

st.markdown("---")
