#!/bin/bash

echo "----------------------------------------------------"
echo "🌐 DocBot Dual Service Exposer (ngrok)"
echo "----------------------------------------------------"

# Ensure Endee and Ollama are running
if ! lsof -i :8080 > /dev/null; then
    echo "⚠️  Warning: Endee does not appear to be running on port 8080."
fi

if ! lsof -i :11434 > /dev/null; then
    echo "⚠️  Warning: Ollama does not appear to be running on port 11434."
fi

echo "🚀 Starting dual tunnels for Endee (8080) and Ollama (11434)..."
echo "----------------------------------------------------"
echo "⚠️  NOTE: ngrok's FREE plan usually only allows ONE tunnel."
echo "   If you get an error 'Too many tunnels', you must use"
echo "   the Unified Proxy method instead: ./docbot/expose_services.sh"
echo "----------------------------------------------------"
echo "Press Ctrl+C to stop."
echo ""

# Start ngrok with the dual config
ngrok start --all --config docbot_dual.yml
