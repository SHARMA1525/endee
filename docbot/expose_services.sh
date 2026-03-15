#!/bin/bash

echo "----------------------------------------------------"
echo "🌐 DocBot Service Exposer (Unified Tunnel)"
echo "----------------------------------------------------"

if ! command -v ngrok &> /dev/null
then
    echo "❌ Error: ngrok is not installed."
    echo "Please download it from https://ngrok.com/download"
    exit 1
fi

# 1. Start the Unified Proxy in the background
echo "🚀 Starting Unified Proxy on port 5000..."
python3 docbot/tunnel_proxy.py > proxy.log 2>&1 &
PROXY_PID=$!

# Ensure proxy is cleaned up on exit
cleanup() {
    echo ""
    echo "Stopping tunnel and proxy..."
    kill $PROXY_PID
    exit 0
}
trap cleanup SIGINT

# Wait for proxy to start
sleep 2

# 2. Start a SINGLE ngrok tunnel to the proxy
echo "🚀 Starting ngrok tunnel to port 5000..."
echo "----------------------------------------------------"
echo "📍 INSTRUCTIONS:"
echo "1. Wait for ngrok to show the 'Forwarding' URL (e.g., https://xyz.ngrok-free.dev)"
echo "2. Copy that SAME URL into BOTH fields in DocBot sidebar:"
echo "   🔹 Endee URL:   [URL]/endee"
echo "   🔹 Ollama Host: [URL]/ollama"
echo "----------------------------------------------------"
echo "Press Ctrl+C to stop."
echo ""

ngrok http 5000
