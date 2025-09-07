#!/bin/bash

echo "🚀 Setting up K3s Lab Rust API"
echo "=============================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust is not installed. Please install Rust from https://rustup.rs/"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Start PostgreSQL database
echo -e "\n📦 Starting PostgreSQL database..."
docker-compose up -d postgres

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo "   Still waiting..."
    sleep 2
done

echo "✅ Database is ready"

# Copy environment file
if [ ! -f .env ]; then
    echo -e "\n📝 Setting up environment file..."
    cp env.example .env
    echo "✅ Environment file created. Please review .env and update if needed."
else
    echo "✅ Environment file already exists"
fi

# Install Diesel CLI if not already installed
if ! command -v diesel &> /dev/null; then
    echo -e "\n🔧 Installing Diesel CLI..."
    cargo install diesel_cli --no-default-features --features postgres
else
    echo "✅ Diesel CLI already installed"
fi

# Set up database schema
echo -e "\n🗄️  Setting up database schema..."
diesel migration run

if [ $? -eq 0 ]; then
    echo "✅ Database schema created successfully"
else
    echo "❌ Failed to create database schema"
    exit 1
fi

# Build the project
echo -e "\n🔨 Building the project..."
cargo build

if [ $? -eq 0 ]; then
    echo "✅ Project built successfully"
else
    echo "❌ Failed to build project"
    exit 1
fi

echo -e "\n🎉 Setup completed successfully!"
echo -e "\n📋 Next steps:"
echo "1. Review and update .env file if needed"
echo "2. Run 'cargo run' to start the API server"
echo "3. Run './test_api.sh' to test the API"
echo -e "\n🌐 API will be available at: http://localhost:8080"
echo "📊 pgAdmin will be available at: http://localhost:8081"


