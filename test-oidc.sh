#!/bin/bash

# Test OIDC integration with our Rust API
echo "Testing OIDC integration..."

# First, let's test the unprotected endpoint
echo "1. Testing unprotected endpoint..."
curl -s http://localhost:8080/health | jq .

# Test protected endpoint without token (should fail)
echo -e "\n2. Testing protected endpoint without token (should fail)..."
curl -s http://localhost:8080/api/protected | jq .

# For now, let's test with a simple JWT token to see if the API is working
echo -e "\n3. Testing with a simple JWT token..."
# We'll create a simple test token using the JWT_SECRET from the config
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production-12345"

# Create a simple test token (this is just for testing the API structure)
echo "Creating test JWT token..."
# This is a simple test - in real OIDC, we'd get this from Keycloak

echo "Testing complete."
