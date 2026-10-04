# Voxray for Jarvis - Vobiz-compatible voice AI
# Multi-stage build
FROM golang:1.25-alpine AS builder
WORKDIR /app

# Copy module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build (CGO disabled for static binary, but gopus needs CGO...
# Use CGO_ENABLED=1 with gcc for opus support)
RUN apk add --no-cache gcc musl-dev
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-w -s" -o /voxray ./cmd/voxray

# Run stage
FROM alpine:3.20
RUN adduser -D -g "" voxray
USER voxray
WORKDIR /app

COPY --from=builder /voxray /voxray
COPY config.json /app/config.json

# Render uses PORT env var
ENV PORT=10000
EXPOSE 10000

ENTRYPOINT ["/voxray"]
CMD ["-config", "/app/config.json"]
