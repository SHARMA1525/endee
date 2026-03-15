#!/bin/bash

# DocBot Fresh Start Script
# This script kills any old services, clears port conflicts, and starts fresh localtunnels.

echo "----------------------------------------------------"
echo "🤖 DocBot Fresh Start (Localtunnel)"
echo "----------------------------------------------------"

# 1. Kill any existing processes on ports 8080, 11434, 5005, and any old lt/ngrok
echo "🛑 Clearing port conflicts (8080, 11434, 5005)..."
lsof -ti :8080 | xargs kill -9 2>/dev/null
lsof -ti :11434 | xargs kill -9 2>/dev/null
lsof -ti :5005 | xargs kill -9 2>/dev/null
pkill -f localtunnel 2>/dev/null
pkill -f ngrok 2>/dev/null
sleep 2

# 2. Start Services
echo "🚀 Starting Endee Vector Database..."
./run.sh &
ENDEE_PID=$!

echo "🚀 Starting Ollama..."
OLLAMA_ORIGINS="*" OLLAMA_HOST="0.0.0.0" ollama serve &
OLLAMA_PID=$!
sleep 5

# 3. Start Localtunnels
echo "🚀 Starting Localtunnel for Endee (8080)..."
npx localtunnel --port 8080 > endee_lt.log 2>&1 &
ENDEE_LT_PID=$!

echo "🚀 Starting Localtunnel for Ollama (11434)..."
npx localtunnel --port 11434 > ollama_lt.log 2>&1 &
OLLAMA_LT_PID=$!

cleanup() {
    echo ""
    echo "🛑 Shutting down DocBot services..."
    kill $ENDEE_PID $OLLAMA_PID $ENDEE_LT_PID $OLLAMA_LT_PID 2>/dev/null
    rm -f endee_lt.log ollama_lt.log
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "⏳ Waiting for stable URLs (10 seconds)..."
sleep 10

# Extract URLs from logs
ENDEE_URL=$(grep -o 'https://[^ ]*' endee_lt.log | head -n 1)
OLLAMA_URL=$(grep -o 'https://[^ ]*' ollama_lt.log | head -n 1)

if [ -z "$ENDEE_URL" ] || [ -z "$OLLAMA_URL" ]; then
    echo "❌ Error: Localtunnel failed to provide URLs. Please restart your internet and try again."
    cleanup
fi

echo "----------------------------------------------------"
echo "📍 YOUR FRESH PUBLIC LINKS:"
echo "----------------------------------------------------"
echo "🔹 Endee URL:   $ENDEE_URL"
echo "🔹 Ollama Host: $OLLAMA_URL"
echo "----------------------------------------------------"
echo "⚠️ IMPORTANT: DO NOT USE OLD NGROK LINKS!"
echo "✅ Copy the TWO links above into the DocBot Sidebar."
echo "----------------------------------------------------"
echo "Press Ctrl+C to stop all services."

wait
