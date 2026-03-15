#!/bin/bash

echo "----------------------------------------------------"
echo "🌐 DocBot Service Exposer (using Localtunnel)"
echo "----------------------------------------------------"

# Ensure Endee and Ollama are running
if ! lsof -i :8080 > /dev/null; then
    echo "⚠️  Warning: Endee is not running on 8080. Start it with ./run.sh"
fi

if ! lsof -i :11434 > /dev/null; then
    echo "⚠️  Warning: Ollama is not running on 11434. Start it with 'ollama serve'"
fi

# Cleanup old log files
rm -f endee_lt.log ollama_lt.log

# 1. Start tunnel for Endee
echo "🚀 Starting tunnel for Endee (8080)..."
npx localtunnel --port 8080 > endee_lt.log 2>&1 &
ENDEE_LT_PID=$!

# 2. Start tunnel for Ollama
echo "🚀 Starting tunnel for Ollama (11434)..."
npx localtunnel --port 11434 > ollama_lt.log 2>&1 &
OLLAMA_LT_PID=$!

# Cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping tunnels..."
    kill $ENDEE_LT_PID 2>/dev/null
    kill $OLLAMA_LT_PID 2>/dev/null
    rm -f endee_lt.log ollama_lt.log
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "⏳ Waiting for URLs..."
sleep 6

ENDEE_URL=$(grep -o 'https://[^ ]*' endee_lt.log | head -n 1)
OLLAMA_URL=$(grep -o 'https://[^ ]*' ollama_lt.log | head -n 1)

if [ -z "$ENDEE_URL" ] || [ -z "$OLLAMA_URL" ]; then
    echo "❌ Error: Could not get URLs. Trying one more time..."
    sleep 4
    ENDEE_URL=$(grep -o 'https://[^ ]*' endee_lt.log | head -n 1)
    OLLAMA_URL=$(grep -o 'https://[^ ]*' ollama_lt.log | head -n 1)
fi

echo "----------------------------------------------------"
echo "📍 Your Public DocBot URLs (Localtunnel):"
echo "----------------------------------------------------"
echo "🔹 Endee URL:  $ENDEE_URL"
echo "🔹 Ollama Host: $OLLAMA_URL"
echo "----------------------------------------------------"
echo "✅ Copy these TWO DIFFERENT links into the Sidebar."
echo "Press Ctrl+C to stop."
echo ""

wait
