# Multi-stage build for K3s Lab Rust API
# Stage 1: Builder stage
FROM rust:1.82-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire project
COPY . .

# Build the application
RUN cargo build --release

# Stage 2: Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1001 -U app

# Set working directory
WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/target/release/k3s-lab-api /app/k3s-lab-api

# Copy migrations
COPY --from=builder /app/migrations/ ./migrations/

# Create necessary directories
RUN mkdir -p /app/data && \
    chown -R app:app /app

# Switch to non-root user
USER app

# Expose port
EXPOSE 8080

# Set environment variables
ENV RUST_LOG=info
ENV RUST_BACKTRACE=1

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["./k3s-lab-api"]
