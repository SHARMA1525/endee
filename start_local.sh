#!/bin/bash

# DocBot Local-Only Startup Script
# Use this for local recording and testing. No ngrok or localtunnel needed.

echo "----------------------------------------------------"
echo "🤖 DocBot Local-Only Mode"
echo "----------------------------------------------------"

# 1. Clear any old stuck processes
echo "🛑 Cleaning up ports (8080, 11434)..."
lsof -ti :8080 | xargs kill -9 2>/dev/null
# We keep Ollama running if it is, but ensure port 11434 is clean or owned by it
pkill -f localtunnel 2>/dev/null
pkill -f ngrok 2>/dev/null
sleep 2

# 2. Start Endee
echo "🚀 Starting Endee Vector Database (Port 8080)..."
./run.sh &
ENDEE_PID=$!

# 3. Start Ollama (if not already running)
if ! pgrep -x "ollama" > /dev/null; then
    echo "🚀 Starting Ollama (Port 11434)..."
    OLLAMA_ORIGINS="*" OLLAMA_HOST="0.0.0.0" ollama serve &
    OLLAMA_PID=$!
else
    echo "✅ Ollama is already running."
fi

sleep 5

# 4. Start Streamlit
echo "🚀 Starting DocBot Dashboard..."
echo "----------------------------------------------------"
echo "📍 LOCAL CONFIGURATION:"
echo "🔹 Endee URL:   http://localhost:8080"
echo "🔹 Ollama Host: http://localhost:11434"
echo "----------------------------------------------------"

streamlit run docbot/app.py
