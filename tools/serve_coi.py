import http.server, os

class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()

if __name__ == "__main__":
    os.chdir("/Users/Admin/Desktop/Contra/export/web")
    http.server.ThreadingHTTPServer(("127.0.0.1", 8766), H).serve_forever()
