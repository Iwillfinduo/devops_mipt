#!/usr/bin/env python3
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            payload = json.dumps({"status": "UP"}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        self.send_error(404)

    def log_message(self, format_string, *args):
        print(format_string % args, flush=True)


host = os.getenv("APP_HOST", "127.0.0.1")
port = int(os.getenv("APP_PORT", "8080"))
ThreadingHTTPServer((host, port), HealthHandler).serve_forever()
