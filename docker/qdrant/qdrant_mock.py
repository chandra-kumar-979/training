from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Handler(BaseHTTPRequestHandler):
    def _set_response(self, code=200):
        self.send_response(code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/collections'):
            self._set_response()
            self.wfile.write(json.dumps({"collections": []}).encode('utf-8'))
            return
        self._set_response(404)
        self.wfile.write(json.dumps({"error": "not found"}).encode('utf-8'))

    def do_PUT(self):
        # Accept create collection and points
        if self.path.startswith('/collections'):
            self._set_response(200)
            self.wfile.write(json.dumps({}).encode('utf-8'))
            return
        self._set_response(404)
        self.wfile.write(json.dumps({"error": "not found"}).encode('utf-8'))

    def do_POST(self):
        if self.path.endswith('/points/search'):
            self._set_response()
            # return empty result list
            self.wfile.write(json.dumps({"result": []}).encode('utf-8'))
            return
        self._set_response(404)
        self.wfile.write(json.dumps({"error": "not found"}).encode('utf-8'))

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 6333), Handler)
    print('Mock qdrant running on 6333')
    server.serve_forever()

