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
echo "🚀 Starting Unified Proxy on port 5005..."
python3 docbot/tunnel_proxy.py &
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
echo "🚀 Starting ngrok tunnel to port 5005..."
ngrok http 5005 --log=stdout > /dev/null &
NGROK_PID=$!

# Ensure everything is cleaned up on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down DocBot services..."
    kill $PROXY_PID 2>/dev/null
    kill $NGROK_PID 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "⏳ Waiting for ngrok to generate URL..."
sleep 5

# Fetch the URL using ngrok's local API
PUBLIC_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "import sys, json; print(json.load(sys.stdin)['tunnels'][0]['public_url'])")

if [ -z "$PUBLIC_URL" ]; then
    echo "❌ Error: Could not get ngrok URL. Please ensure ngrok is running and you have internet."
    cleanup
fi

echo "----------------------------------------------------"
echo "📍 YOUR PUBLIC DOCBOT LINKS:"
echo "----------------------------------------------------"
echo "🔹 Endee URL:   $PUBLIC_URL/endee"
echo "🔹 Ollama Host: $PUBLIC_URL/ollama"
echo "----------------------------------------------------"
echo "✅ Copy these two links into the DocBot Sidebar."
echo "Press Ctrl+C to stop."
echo ""

# Keep script running to show proxy logs
wait $NGROK_PID
