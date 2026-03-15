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
echo "📍 INSTRUCTIONS:"
echo "1. Copy the ngrok 'Forwarding' URL."
echo "2. In DocBot Sidebar, set BOTH Endee and Ollama to that URL"
echo "   (appending /endee and /ollama respectively)."
echo "----------------------------------------------------"

ngrok http 5005
