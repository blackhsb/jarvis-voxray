# Voxray for Jarvis - Vobiz-compatible voice AI
# Multi-stage build
FROM golang:1.25-alpine AS builder
WORKDIR /app

# Extract voxray source from tarball
COPY voxray-jarvis.tar.gz /tmp/
RUN tar -xzf /tmp/voxray-jarvis.tar.gz -C /tmp/ && cp -r /tmp/voxray/* /app/ && rm -rf /tmp/voxray /tmp/voxray-jarvis.tar.gz

# Copy config
COPY config.json /app/config.json

# Install build deps and download modules
RUN apk add --no-cache gcc musl-dev
RUN go mod download

# Build
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-w -s" -o /voxray ./cmd/voxray

# Run stage
FROM alpine:3.20
RUN adduser -D -g "" voxray
USER voxray
WORKDIR /app

COPY --from=builder /voxray /voxray
COPY --from=builder /app/config.json /app/config.json

# Render uses PORT env var
ENV PORT=10000
EXPOSE 10000

ENTRYPOINT ["/voxray"]
CMD ["-config", "/app/config.json"]
