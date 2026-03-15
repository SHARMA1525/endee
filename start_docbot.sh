#!/bin/bash

# DocBot Unified Startup Script
# This script starts Endee, Ollama, the Unified Proxy, and ngrok in one go.

echo "----------------------------------------------------"
echo "🤖 DocBot Master Startup"
echo "----------------------------------------------------"

# 1. Start Ollama (if not already running)
if ! pgrep -x "ollama" > /dev/null; then
    echo "🚀 Starting Ollama..."
    OLLAMA_ORIGINS="*" OLLAMA_HOST="0.0.0.0" ollama serve &
    OLLAMA_PID=$!
    sleep 5
else
    echo "✅ Ollama is already running."
fi

# 2. Start Endee
echo "🚀 Starting Endee Vector Database..."
./run.sh &
ENDEE_PID=$!
sleep 3

# 3. Start Unified Proxy (Port 5005)
echo "🚀 Starting Unified Proxy..."
python3 docbot/tunnel_proxy.py &
PROXY_PID=$!
sleep 2

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Shutting down DocBot services..."
    kill $PROXY_PID 2>/dev/null
    kill $ENDEE_PID 2>/dev/null
    # We don't necessarily want to kill ollama as it might be a system service
    # but we can kill the tunnel.
    pkill ngrok 2>/dev/null
    echo "✅ Shutdown complete."
    exit 0
}

trap cleanup SIGINT SIGTERM

# 4. Start ngrok Tunnel
echo "----------------------------------------------------"
echo "🌐 Starting Public Tunnel..."
echo "----------------------------------------------------"
ngrok http 5005 --log=stdout > /dev/null &
NGROK_PID=$!

echo "⏳ Waiting for ngrok to generate URL..."
sleep 5

# Fetch the URL using ngrok's local API
PUBLIC_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "import sys, json; print(json.load(sys.stdin)['tunnels'][0]['public_url'])")

if [ -z "$PUBLIC_URL" ]; then
    echo "❌ Error: Could not get ngrok URL. Please ensure ngrok is running and you have internet."
    kill $PROXY_PID 2>/dev/null
    kill $ENDEE_PID 2>/dev/null
    exit 1
fi

echo "----------------------------------------------------"
echo "📍 YOUR PUBLIC DOCBOT LINKS:"
echo "----------------------------------------------------"
echo "🔹 Endee URL:   $PUBLIC_URL/endee"
echo "🔹 Ollama Host: $PUBLIC_URL/ollama"
echo "----------------------------------------------------"
echo "✅ Copy these two links into the DocBot Sidebar!"
echo "Press Ctrl+C to stop all services."
echo ""

# Wait for ngrok to finish (allows proxy logs to show)
wait $NGROK_PID
