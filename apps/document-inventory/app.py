#!/usr/bin/env python3

import html
import json
import logging
import os
import re
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit
from uuid import uuid4


DOCUMENTS = (
    {
        "document_id": "DOC-1001",
        "name": "Vendor onboarding checklist",
        "status": "under-review",
        "created_date": "2026-01-15",
    },
    {
        "document_id": "DOC-1002",
        "name": "Cloud controls assessment",
        "status": "approved",
        "created_date": "2026-02-02",
    },
    {
        "document_id": "DOC-1003",
        "name": "Service continuity plan",
        "status": "draft",
        "created_date": "2026-02-18",
    },
)

LOGGER = logging.getLogger("securecloudops.inventory")
REQUEST_ID_PATTERN = re.compile(r"[A-Za-z0-9._-]{1,64}\Z")


def configure_logging():
    LOGGER.setLevel(logging.INFO)
    LOGGER.handlers.clear()
    formatter = logging.Formatter("%(message)s")
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    LOGGER.addHandler(stream_handler)

    log_path = os.environ.get("APP_LOG_PATH")
    if log_path:
        file_handler = logging.FileHandler(log_path)
        file_handler.setFormatter(formatter)
        LOGGER.addHandler(file_handler)


class InventoryHandler(BaseHTTPRequestHandler):
    server_version = "SecureCloudOpsInventory"
    sys_version = ""

    def do_GET(self):
        started = time.monotonic()
        status = 500
        route = urlsplit(self.path).path

        try:
            if route == "/health":
                status = 200
                self._send_json(status, {"status": "ok"})
            elif route == "/api/documents":
                status = 200
                self._send_json(status, {"documents": DOCUMENTS})
            elif route == "/":
                status = 200
                self._send_html(status, self._render_inventory())
            else:
                status = 404
                self._send_json(status, {"error": "not_found"})
        finally:
            self._log_request(route, status, started)

    def do_POST(self):
        self._method_not_allowed()

    def do_PUT(self):
        self._method_not_allowed()

    def do_DELETE(self):
        self._method_not_allowed()

    def log_message(self, _format, *_args):
        return

    def _send_json(self, status, payload):
        self._send(status, "application/json; charset=utf-8", json.dumps(payload).encode())

    def _send_html(self, status, payload):
        self._send(status, "text/html; charset=utf-8", payload.encode())

    def _send(self, status, content_type, body):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()
        self.wfile.write(body)

    def _method_not_allowed(self):
        started = time.monotonic()
        status = 405
        try:
            self._send_json(status, {"error": "method_not_allowed"})
        finally:
            self._log_request(urlsplit(self.path).path, status, started)

    def _log_request(self, route, status, started):
        request_id = self.headers.get("X-Request-ID", "")
        if not REQUEST_ID_PATTERN.fullmatch(request_id):
            request_id = uuid4().hex

        LOGGER.info(
            json.dumps(
                {
                    "event": "http_request",
                    "request_id": request_id,
                    "method": self.command,
                    "route": route,
                    "status": status,
                    "duration_ms": round((time.monotonic() - started) * 1000, 2),
                },
                separators=(",", ":"),
            )
        )

    @staticmethod
    def _render_inventory():
        rows = "\n".join(
            "<tr><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
                html.escape(document["document_id"]),
                html.escape(document["name"]),
                html.escape(document["status"]),
                html.escape(document["created_date"]),
            )
            for document in DOCUMENTS
        )
        return (
            "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
            "<title>SecureCloudOps Document Inventory</title></head><body>"
            "<main><h1>Document inventory</h1>"
            "<p>Read-only demonstration using synthetic records.</p>"
            "<table><thead><tr><th>ID</th><th>Name</th><th>Status</th>"
            "<th>Created</th></tr></thead><tbody>"
            + rows
            + "</tbody></table></main></body></html>"
        )


def main():
    configure_logging()
    server = ThreadingHTTPServer(("0.0.0.0", 8080), InventoryHandler)
    LOGGER.info(json.dumps({"event": "service_started", "port": 8080}))
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
