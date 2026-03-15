echo "----------------------------------------------------"
echo "🌐 DocBot Service Exposer (using ngrok)"
echo "----------------------------------------------------"

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

CONFIG_PATH="$HOME/Library/Application Support/ngrok/ngrok.yml"
[ ! -f "$CONFIG_PATH" ] && CONFIG_PATH="$HOME/.config/ngrok/ngrok.yml"

if [ -f "$CONFIG_PATH" ]; then
    echo "Checking for ngrok configuration at $CONFIG_PATH..."
    
    # Extract authtoken more robustly using sed (handles quotes and spaces)
    AUTH_TOKEN=$(grep "authtoken:" "$CONFIG_PATH" | head -n 1 | sed -e 's/authtoken: //' -e 's/"//g' -e "s/'//g" | xargs)

    if [ -z "$AUTH_TOKEN" ]; then
        echo "⚠️  Warning: Could not extract authtoken from $CONFIG_PATH."
        echo "Starting in single tunnel mode (requires manual second tunnel for Ollama)."
        ngrok http 8080
        exit 0
    fi

    cat <<EOF > docbot_ngrok.yml
version: "2"
authtoken: $AUTH_TOKEN
tunnels:
  endee:
    proto: http
    addr: 8080
  ollama:
    proto: http
    addr: 11434
EOF

    # Start ngrok in the background
    echo "🚀 Starting tunnels for Endee (8080) and Ollama (11434)..."
    ngrok start --config docbot_ngrok.yml --all > /dev/null &
    NGROK_PID=$!

    # Wait for tunnels to initialize
    sleep 3

    # Query the local ngrok API to get the public URLs
    echo "----------------------------------------------------"
    echo "📍 Your Public DocBot URLs:"
    echo "----------------------------------------------------"
    
    ENDEE_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*endee[^"]*' | head -n 1)
    OLLAMA_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*ollama[^"]*' | head -n 1)

    # Fallback if names aren't in URLs (common in free plan)
    if [ -z "$ENDEE_URL" ]; then
        ENDEE_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; print([t['public_url'] for t in json.load(sys.stdin)['tunnels'] if '8080' in t['config']['addr']][0])" 2>/dev/null)
        OLLAMA_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; print([t['public_url'] for t in json.load(sys.stdin)['tunnels'] if '11434' in t['config']['addr']][0])" 2>/dev/null)
    fi

    echo "🔹 Endee URL:  $ENDEE_URL"
    echo "🔹 Ollama Host: $OLLAMA_URL"
    echo "----------------------------------------------------"
    echo "Copy these into your Streamlit sidebar!"
    echo "Press Ctrl+C to stop the tunnels."
    
    # Wait for the background process
    wait $NGROK_PID
else
    echo "No ngrok config found. Starting a single tunnel for Endee first..."
    echo "Please open another terminal for Ollama: 'ngrok http 11434'"
    ngrok http 8080
fi
