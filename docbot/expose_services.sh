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
    
    # Create a temporary config for both services with the required version property
    # We use the system config's authtoken automatically if we don't specify it,
    # but to be safe and explicit with multiple tunnels, we pull it.
    AUTH_TOKEN=$(grep "authtoken:" "$CONFIG_PATH" | head -n 1 | cut -d ' ' -f 2)

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

    echo "🚀 Starting tunnels for Endee (8080) and Ollama (11434)..."
    echo "Once started, copy the 'Forwarding' URLs into your DocBot UI."
    echo "Press Ctrl+C to stop."
    ngrok start --config docbot_ngrok.yml --all
else
    echo "No ngrok config found. Starting a single tunnel for Endee first..."
    echo "Please open another terminal for Ollama: 'ngrok http 11434'"
    ngrok http 8080
fi
