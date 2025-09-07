#!/usr/bin/env python3
"""
Mock JWKS server for testing OIDC integration
"""
import json
import base64
from http.server import HTTPServer, BaseHTTPRequestHandler
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
import jwt
import time

# Generate RSA key pair for testing
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
)

public_key = private_key.public_key()

# Get key components for JWKS
public_numbers = public_key.public_numbers()
n = public_numbers.n
e = public_numbers.e

# Convert to base64url encoding
n_b64 = base64.urlsafe_b64encode(n.to_bytes(256, 'big')).decode('ascii').rstrip('=')
e_b64 = base64.urlsafe_b64encode(e.to_bytes(3, 'big')).decode('ascii').rstrip('=')

# Create JWKS
jwks = {
    "keys": [
        {
            "kty": "RSA",
            "kid": "test-key-1",
            "n": n_b64,
            "e": e_b64,
            "alg": "RS256",
            "use": "sig"
        }
    ]
}

class MockJWKSHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/.well-known/openid_configuration':
            # Return OIDC configuration
            config = {
                "issuer": "http://localhost:8083",
                "authorization_endpoint": "http://localhost:8083/auth",
                "token_endpoint": "http://localhost:8083/token",
                "jwks_uri": "http://localhost:8083/jwks",
                "response_types_supported": ["code", "id_token", "token"],
                "subject_types_supported": ["public"],
                "id_token_signing_alg_values_supported": ["RS256"]
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(config).encode())
        elif self.path == '/jwks':
            # Return JWKS
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(jwks).encode())
        elif self.path == '/token':
            # Return a test token
            now = int(time.time())
            payload = {
                "sub": "test-user-123",
                "iss": "http://localhost:8083",
                "aud": "lab-api",
                "exp": now + 3600,
                "iat": now,
                "jti": "test-jti-123"
            }
            
            # Create JWT token
            token = jwt.encode(payload, private_key, algorithm='RS256', headers={'kid': 'test-key-1'})
            
            response = {
                "access_token": token,
                "token_type": "Bearer",
                "expires_in": 3600
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('localhost', 8083), MockJWKSHandler)
    print("Mock JWKS server running on http://localhost:8083")
    print("JWKS endpoint: http://localhost:8083/jwks")
    print("Token endpoint: http://localhost:8083/token")
    print("OIDC config: http://localhost:8083/.well-known/openid_configuration")
    server.serve_forever()
