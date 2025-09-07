#!/bin/bash

set -e

echo "🚀 Deploying K3s Lab Rust API to Production"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_status "Docker is available and running"

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Docker Compose is available"

# Check if .env.production exists
if [ ! -f .env.production ]; then
    print_warning "Production environment file not found. Creating from template..."
    cp env.production .env.production
    print_warning "Please edit .env.production with your production values before continuing."
    print_warning "Especially update:"
    print_warning "  - POSTGRES_PASSWORD (use a strong password)"
    print_warning "  - JWT_SECRET (use a long random string)"
    print_warning "  - PGADMIN_EMAIL and PGADMIN_PASSWORD"
    echo ""
    read -p "Press Enter after updating .env.production to continue..."
fi

# Validate environment file
if ! grep -q "your_very_secure_database_password_here" .env.production; then
    print_status "Environment file appears to be configured"
else
    print_error "Please update .env.production with real values before deploying"
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p nginx/ssl

# Generate self-signed SSL certificate for development (optional)
if [ ! -f nginx/ssl/cert.pem ]; then
    print_warning "Generating self-signed SSL certificate for development..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    print_status "SSL certificate generated"
fi

# Stop existing containers if running
print_status "Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down --remove-orphans || true

# Build and start services
print_status "Building and starting services..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check service health
print_status "Checking service health..."

# Check PostgreSQL
if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U postgres &> /dev/null; then
    print_status "PostgreSQL is healthy"
else
    print_error "PostgreSQL is not healthy"
    docker-compose -f docker-compose.prod.yml logs postgres
    exit 1
fi

# Check Rust API
if curl -f http://localhost:8080/health &> /dev/null; then
    print_status "Rust API is healthy"
else
    print_error "Rust API is not responding"
    docker-compose -f docker-compose.prod.yml logs rust-api
    exit 1
fi

# Check Nginx
if curl -f http://localhost/health &> /dev/null; then
    print_status "Nginx reverse proxy is working"
else
    print_warning "Nginx reverse proxy is not responding (this might be expected if SSL is not configured)"
fi

# Display deployment information
echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Service Information:"
echo "  🌐 API Endpoint: http://localhost:8080"
echo "  🔒 API with Nginx: http://localhost (redirects to https)"
echo "  📊 pgAdmin: http://localhost:8081"
echo "  🗄️  PostgreSQL: localhost:5432"
echo ""
echo "🔐 Database Credentials:"
echo "  Database: k3s_lab_api"
echo "  Username: postgres"
echo "  Password: [from your .env.production file]"
echo ""
echo "📝 Useful Commands:"
echo "  View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  Stop services: docker-compose -f docker-compose.prod.yml down"
echo "  Restart services: docker-compose -f docker-compose.prod.yml restart"
echo "  Update and redeploy: ./deploy-prod.sh"
echo ""
echo "🔒 Security Notes:"
echo "  - Change default passwords in .env.production"
echo "  - Configure proper SSL certificates for production"
echo "  - Set up firewall rules to restrict access"
echo "  - Regularly update dependencies and monitor logs"


