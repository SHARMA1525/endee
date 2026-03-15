#!/bin/bash

# DocBot Service Exposer
# This script helps you create public URLs for your local Endee and Ollama services
# so that a hosted Streamlit app can reach them.

echo "----------------------------------------------------"
echo "🌐 DocBot Service Exposer (using ngrok)"
echo "----------------------------------------------------"

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null
then
    echo "❌ Error: ngrok is not installed."
    echo "Please download it from https://ngrok.com/download"
    exit 1
fi

echo "💡 Note: To run multiple tunnels, you need an ngrok account and auth token."
echo "If you don't have one, run these in two separate terminal windows manually:"
echo "Terminal 1: ngrok http 8080"
echo "Terminal 2: ngrok http 11434"
echo ""

# Try to run multi-tunnel if config exists, otherwise prompt
if [ -f "$HOME/.config/ngrok/ngrok.yml" ] || [ -f "$HOME/Library/Application Support/ngrok/ngrok.yml" ]; then
    echo "Checking for ngrok configuration..."
    
    # Create a temporary config for both services
    cat <<EOF > docbot_ngrok.yml
authtoken: $(ngrok config check | grep -o 'authtoken: .*' | cut -d ' ' -f 2)
tunnels:
  endee:
    proto: http
    addr: 8080
  ollama:
    proto: http
    addr: 11434
EOF

    echo "🚀 Starting tunnels for Endee (8080) and Ollama (11434)..."
    echo "Once started, copy the 'Forwarding' URLs into your DocBot UI."
    echo "Press Ctrl+C to stop."
    ngrok start --config docbot_ngrok.yml --all
else
    echo "No ngrok config found. Starting a single tunnel for Endee first..."
    echo "Please open another terminal for Ollama: 'ngrok http 11434'"
    ngrok http 8080
fi
