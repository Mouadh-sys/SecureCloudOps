import json
import threading
import unittest
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from app import DOCUMENTS, InventoryHandler


class InventoryAppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), InventoryHandler)
        cls.server_thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.server_thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.server_thread.join(timeout=2)

    def test_health_endpoint(self):
        with urlopen(f"{self.base_url}/health") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(json.load(response), {"status": "ok"})

    def test_inventory_endpoint_returns_only_synthetic_records(self):
        with urlopen(f"{self.base_url}/api/documents") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(json.load(response), {"documents": list(DOCUMENTS)})

    def test_root_renders_inventory(self):
        with urlopen(self.base_url) as response:
            page = response.read().decode()
            self.assertEqual(response.status, 200)
            self.assertIn("Read-only demonstration using synthetic records.", page)
            self.assertIn("DOC-1001", page)

    def test_unknown_route_returns_not_found(self):
        with self.assertRaises(HTTPError) as error:
            urlopen(f"{self.base_url}/missing")
        self.assertEqual(error.exception.code, 404)
        self.assertEqual(json.load(error.exception), {"error": "not_found"})

    def test_write_method_is_rejected(self):
        request = Request(f"{self.base_url}/api/documents", method="POST")
        with self.assertRaises(HTTPError) as error:
            urlopen(request)
        self.assertEqual(error.exception.code, 405)
        self.assertEqual(json.load(error.exception), {"error": "method_not_allowed"})


if __name__ == "__main__":
    unittest.main()
