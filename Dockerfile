# Build stage
FROM golang:1.24-bookworm AS builder

WORKDIR /app

# Install build dependencies for LMDB
RUN apt-get update && apt-get install -y \
    build-essential \
    liblmdb-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Copy local dependencies (replacements in go.mod)
COPY khatru/ ./khatru/
COPY go-nostr/ ./go-nostr/

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -o /relay29 ./groups.0xchat.com

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies for LMDB
RUN apt-get update && apt-get install -y \
    liblmdb0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /relay29 /app/relay29

# Create directory for database
RUN mkdir -p /app/db

# Expose default port
EXPOSE 5577

# Run the application
CMD ["/app/relay29"]
