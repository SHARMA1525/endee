#!/bin/bash

# DocBot Service Exposer (Localtunnel Edition)
# This script creates public URLs for your local Endee and Ollama services.
# Localtunnel is used as a free alternative to ngrok that allows multiple tunnels.

echo "----------------------------------------------------"
echo "🌐 DocBot Service Exposer (using Localtunnel)"
echo "----------------------------------------------------"

# Check if npx is installed
if ! command -v npx &> /dev/null
then
    echo "❌ Error: npx/node is not installed."
    exit 1
fi

echo "🚀 Starting tunnels for Endee (8080) and Ollama (11434)..."
echo "Please wait a moment for the URLs to appear."
echo "Press Ctrl+C to stop."
echo ""

# Start Localtunnel for Endee
npx localtunnel --port 8080 > lt_endee.txt &
ENDEE_PID=$!

# Start Localtunnel for Ollama
npx localtunnel --port 11434 > lt_ollama.txt &
OLLAMA_PID=$!

# Function to cleaner exit
cleanup() {
    echo ""
    echo "Stopping tunnels..."
    kill $ENDEE_PID $OLLAMA_PID
    rm lt_endee.txt lt_ollama.txt
    exit 0
}
trap cleanup SIGINT

# Wait and print URLs
sleep 5
echo "----------------------------------------------------"
echo "📍 Your Public DocBot URLs:"
echo "----------------------------------------------------"
echo "🔹 Endee URL:  $(grep -o 'https://[^ ]*' lt_endee.txt)"
echo "🔹 Ollama Host: $(grep -o 'https://[^ ]*' lt_ollama.txt)"
echo "----------------------------------------------------"
echo "💡 IMPORTANT: If you see a 'Friendly Reminder' page, it's normal."
echo "DocBot is configured to skip it automatically!"
echo "----------------------------------------------------"

# Keep the script running
wait
