#!/usr/bin/env python3
"""本地预览服务器: 在静态文件基础上追加 no-cache 头, 避免浏览器缓存旧版 index.pck"""
import http.server
import socketserver
import sys

PORT = 8767
DIRECTORY = sys.argv[1] if len(sys.argv) > 1 else "export/web"


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


class ReuseTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with ReuseTCPServer(("127.0.0.1", PORT), NoCacheHandler) as httpd:
        print(f"serving {DIRECTORY} at http://127.0.0.1:{PORT} (no-cache)")
        httpd.serve_forever()
