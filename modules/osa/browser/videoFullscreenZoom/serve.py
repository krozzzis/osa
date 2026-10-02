#!/usr/bin/env python3
"""Serve Tampermonkey provisioning through a systemd user socket."""

import http.server
import os
import socket
import sys


if __name__ == "__main__":
    if os.environ.get("LISTEN_FDS") != "1" or os.environ.get("LISTEN_PID") != str(os.getpid()):
        raise SystemExit("expected one systemd socket")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=sys.argv[1], **kwargs)

        def do_GET(self):
            if self.path == "/enabled":
                payload = b"2\n"
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
            else:
                super().do_GET()

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 17837), Handler, bind_and_activate=False)
    server.socket.close()
    server.socket = socket.socket(fileno=3)
    server.server_address = server.socket.getsockname()
    server.serve_forever()
