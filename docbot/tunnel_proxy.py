import http.server
import http.client
import socketserver
import urllib.parse
import os

# Configuration
PORT = 5005
ENDEE_HOST = "127.0.0.1"
ENDEE_PORT = 8080
OLLAMA_HOST = "127.0.0.1"
OLLAMA_PORT = 11434

class UnifiedProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.handle_proxy()

    def do_POST(self):
        self.handle_proxy()

    def handle_proxy(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        if path == "/" or path == "" or path == "/health":
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"DocBot Unified Tunnel Proxy is ACTIVE!<br/>Paths: /endee, /ollama")
            return

        # Determine target
        if path.startswith("/endee"):
            target_host = ENDEE_HOST
            target_port = ENDEE_PORT
            target_path = path[len("/endee"):]
            service_name = "ENDEE"
        elif path.startswith("/ollama"):
            target_host = OLLAMA_HOST
            target_port = OLLAMA_PORT
            target_path = path[len("/ollama"):]
            service_name = "OLLAMA"
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Unknown service path. Use /endee or /ollama")
            return

        print(f"DEBUG: Routing {self.command} {path} -> {service_name} ({target_path})")

        if not target_path:
            target_path = "/"
        
        # Add query string back
        if parsed_path.query:
            target_path += "?" + parsed_path.query

        # Prepare request to local service
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None
        
        headers = {k: v for k, v in self.headers.items() if k.lower() != 'host'}
        # Specific bypass headers for safety
        headers["ngrok-skip-browser-warning"] = "true"
        headers["Bypass-Tunnel-Reminder"] = "true"

        try:
            conn = http.client.HTTPConnection(target_host, target_port, timeout=30)
            conn.request(self.command, target_path, body, headers)
            response = conn.getresponse()
            
            print(f"DEBUG: {service_name} returned status {response.status}")

            self.send_response(response.status)
            for k, v in response.getheaders():
                if k.lower() != 'transfer-encoding':
                    self.send_header(k, v)
            self.end_headers()
            
            # Use chunks to handle streaming better and catch broken pipes
            while True:
                chunk = response.read(8192)
                if not chunk:
                    break
                try:
                    self.wfile.write(chunk)
                    self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    print(f"INFO: Client disconnected during {service_name} response.")
                    break
            conn.close()
        except Exception as e:
            print(f"ERROR: Proxy failed to connect to {service_name}: {e}")
            try:
                self.send_response(502)
                self.end_headers()
                err_msg = f"DocBot Proxy Error: Could not connect to {service_name}. Is it running at {target_host}:{target_port}? | Error: {e}"
                self.wfile.write(err_msg.encode())
            except:
                pass # Already disconnected

if __name__ == "__main__":
    print(f"🚀 Unified Proxy listening on port {PORT}")
    print(f"🔗 Routing /endee -> {ENDEE_HOST}:{ENDEE_PORT}")
    print(f"🔗 Routing /ollama -> {OLLAMA_HOST}:{OLLAMA_PORT}")
    
    with socketserver.TCPServer(("", PORT), UnifiedProxyHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
