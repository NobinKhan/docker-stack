from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class JSONHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = {"status": "ok", "message": "running"}
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8000), JSONHandler)
    print("Starting server on port 0.0.0.0:8000")
    server.serve_forever()
