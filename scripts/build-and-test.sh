#!/bin/bash

echo "🔨 Quick Build and Test"
echo "======================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration
IMAGE_NAME="k3s-lab-api"
IMAGE_TAG="latest"

cd rust-api

echo ""
print_info "Building Docker image..."

if docker build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
    print_success "Image built successfully"
else
    print_error "Build failed"
    exit 1
fi

echo ""
print_info "Image details:"
docker images "$IMAGE_NAME:$IMAGE_TAG"

echo ""
print_info "Testing container..."

# Run container with basic test
docker run --rm -d --name test-api \
    -e DATABASE_URL=postgres://postgres:password@host.docker.internal:5432/k3s_lab_api \
    -e JWT_SECRET=test-secret \
    -p 8080:8080 \
    "$IMAGE_NAME:$IMAGE_TAG"

# Wait a moment for startup
sleep 5

# Test health endpoint
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    print_success "Container is running and responding"
else
    print_error "Container health check failed"
    docker logs test-api
fi

# Cleanup
docker stop test-api 2>/dev/null || true

echo ""
print_success "Build and test completed!"
