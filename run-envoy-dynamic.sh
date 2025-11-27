#!/bin/bash

# Run Envoy with dynamic routing configuration
# This config allows Envoy to route to ANY destination based on Host header

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/envoy-dynamic.yaml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: envoy-dynamic.yaml not found at $CONFIG_FILE"
    exit 1
fi

# Stop any existing Envoy container
echo "Stopping existing envoy-poc container (if any)..."
docker stop envoy-poc 2>/dev/null || true
docker rm envoy-poc 2>/dev/null || true

# Start Envoy with dynamic config
echo "Starting Envoy with dynamic routing..."
docker run -d \
  --name envoy-poc \
  --platform linux/arm64 \
  -p 10000:10000 \
  -p 9901:9901 \
  -v "$CONFIG_FILE:/etc/envoy/envoy.yaml:ro" \
  envoyproxy/envoy:v1.31-latest

echo ""
echo "✅ Envoy started with DYNAMIC ROUTING!"
echo ""
echo "This config routes to ANY destination based on Host header"
echo ""
echo "Test with:"
echo "  elixir test-dynamic.exs"
echo ""
echo "Or manually:"
echo "  curl -H 'Host: httpbin.org' http://localhost:10000/get"
echo "  curl -H 'Host: api.github.com' http://localhost:10000/zen"
echo ""
echo "View logs:"
echo "  docker logs -f envoy-poc"
