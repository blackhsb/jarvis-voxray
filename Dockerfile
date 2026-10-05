# Voxray for Jarvis - Vobiz-compatible voice AI
# Clones upstream voxray and applies Vobiz patches
FROM golang:1.25-alpine AS builder
WORKDIR /app

# Install git and build deps
RUN apk add --no-cache git gcc musl-dev

# Clone upstream voxray
RUN git clone https://github.com/wayast/voxray.git /app && cd /app && git checkout 4747b666177a0ae9f05fe276ba6671202628e270

# Copy and apply Vobiz patch
COPY voxray-vobiz.patch /tmp/
RUN cd /app && git apply --check /tmp/voxray-vobiz.patch && git apply /tmp/voxray-vobiz.patch

# Copy config
COPY config.json /app/config.json

# Download modules and build
RUN go mod download
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
