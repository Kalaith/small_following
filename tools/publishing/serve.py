"""Local browser verification only: python tools/publishing/serve.py [--port 8062]."""
import argparse
import functools
import http.server
import json
from pathlib import Path


class GodotHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8062)
    args = parser.parse_args()
    builds = Path(__file__).resolve().parents[2] / "builds" / "publish"
    build_id = json.loads((builds / "latest.json").read_text())["id"]
    import re
    if not re.fullmatch(r"[a-f0-9]{32}", build_id):
        raise ValueError("Invalid build pointer")
    directory = builds / build_id / "web"
    handler = functools.partial(GodotHandler, directory=str(directory))
    print(f"Serving {directory} at http://localhost:{args.port}", flush=True)
    http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
