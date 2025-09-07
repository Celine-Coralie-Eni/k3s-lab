# K3s Lab Rust API

A modern Rust API built with Actix-web, Diesel ORM, and PostgreSQL for the K3s Lab project.

## Features

- **RESTful API** with Actix-web framework
- **Database Integration** with Diesel ORM and PostgreSQL
- **Authentication** with JWT tokens and bcrypt password hashing
- **Two Main Entities**: Users and Tasks
- **Input Validation** with validator crate
- **CORS Support** for frontend integration
- **Comprehensive Error Handling**

## Prerequisites

- Rust (latest stable version)
- PostgreSQL 15+
- Docker and Docker Compose (for local development)

## Quick Start

### 1. Set up the Database

```bash
# Start PostgreSQL with Docker Compose
docker-compose up -d postgres

# Wait for the database to be ready
docker-compose logs postgres
```

### 2. Configure Environment

```bash
# Copy the example environment file
cp env.example .env

# Edit .env with your configuration
# Make sure to change the JWT_SECRET for production
```

### 3. Install Diesel CLI (if not already installed)

```bash
cargo install diesel_cli --no-default-features --features postgres
```

### 4. Run Database Migrations

```bash
# Set up the database schema
diesel migration run
```

### 5. Build and Run

```bash
# Build the project
cargo build

# Run the API server
cargo run
```

The API will be available at `http://localhost:8080`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user

### Users (requires authentication)
- `GET /api/users` - Get all users
- `GET /api/users/{id}` - Get specific user
- `POST /api/users` - Create user (admin only)
- `PUT /api/users/{id}` - Update user (own profile only)
- `DELETE /api/users/{id}` - Delete user (own account only)

### Tasks (requires authentication)
- `GET /api/tasks` - Get user's tasks
- `GET /api/tasks/{id}` - Get specific task
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task

### Health Check
- `GET /health` - API health status

## Example Usage

### Register a User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "securepassword123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securepassword123"
  }'
```

### Create a Task (with authentication)
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Complete Rust API",
    "description": "Finish the K3s Lab Rust API implementation"
  }'
```

## Project Structure

```
rust-api/
├── src/
│   ├── main.rs          # Application entry point
│   ├── models.rs         # Data models and DTOs
│   ├── schema.rs         # Database schema (auto-generated)
│   ├── auth.rs           # JWT authentication utilities
│   ├── db.rs             # Database connection and migrations
│   └── handlers/         # HTTP request handlers
│       ├── mod.rs
│       ├── auth.rs       # Authentication endpoints
│       ├── users.rs      # User management endpoints
│       ├── tasks.rs      # Task management endpoints
│       └── health.rs     # Health check endpoint
├── migrations/           # Database migrations
├── Cargo.toml           # Dependencies and project config
├── docker-compose.yml   # Local development database
└── README.md            # This file
```

## Development

### Running Tests
```bash
cargo test
```

### Code Formatting
```bash
cargo fmt
```

### Linting
```bash
cargo clippy
```

### Database Management
```bash
# Create a new migration
diesel migration generate migration_name

# Run migrations
diesel migration run

# Revert last migration
diesel migration revert
```

## Security Features

- **Password Hashing**: Uses bcrypt for secure password storage
- **JWT Authentication**: Stateless authentication with configurable expiration
- **Input Validation**: Comprehensive validation for all inputs
- **SQL Injection Protection**: Diesel ORM provides type-safe queries
- **CORS Configuration**: Configurable CORS for frontend integration

## Production Deployment

1. Set proper environment variables
2. Use a production PostgreSQL instance
3. Configure proper logging
4. Set up reverse proxy (nginx/traefik)
5. Use HTTPS in production
6. Rotate JWT secrets regularly

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is part of the K3s Lab learning environment.


