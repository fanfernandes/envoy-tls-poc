#!/bin/bash

# Envoy TLS Origination POC - Docker Runner
# This script starts Envoy in Docker with the configuration for TLS origination

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/envoy.yaml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: envoy.yaml not found at $CONFIG_FILE"
    exit 1
fi

# Stop any existing Envoy container
echo "Stopping existing envoy-poc container (if any)..."
docker stop envoy-poc 2>/dev/null || true
docker rm envoy-poc 2>/dev/null || true

# Start Envoy
echo "Starting Envoy proxy..."
docker run -d \
  --name envoy-poc \
  --platform linux/arm64 \
  -p 10000:10000 \
  -p 9901:9901 \
  -v "$CONFIG_FILE:/etc/envoy/envoy.yaml:ro" \
  envoyproxy/envoy:v1.31-latest

echo ""
echo "✅ Envoy started successfully!"
echo ""
echo "Endpoints:"
echo "  - HTTP Listener: http://localhost:10000"
echo "  - Admin Interface: http://localhost:9901"
echo ""
echo "Test with:"
echo "  curl http://localhost:10000/get"
echo ""
echo "View logs:"
echo "  docker logs -f envoy-poc"
echo ""
echo "Stop Envoy:"
echo "  docker stop envoy-poc"
