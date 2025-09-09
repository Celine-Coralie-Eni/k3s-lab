# --- Build stage ---
FROM rust:1.80-bullseye AS builder
WORKDIR /app
# Create minimal cargo setup to leverage caching
RUN USER=root cargo new --bin hello-world-app
WORKDIR /app/hello-world-app
COPY Cargo.toml ./
RUN cargo fetch
# Copy source and build release
COPY src ./src
RUN cargo build --release

# --- Runtime stage ---
FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/hello-world-app/target/release/hello-world-app /usr/local/bin/hello-world-app
ENV RUST_LOG=info
EXPOSE 8080
CMD ["/usr/local/bin/hello-world-app"]
