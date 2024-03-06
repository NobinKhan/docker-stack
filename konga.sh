#!/bin/bash

set -e  # Exit on error

# Load environment variables
source .env

# Confirm Docker/Podman availability
if ! command -v "docker" >/dev/null 2>&1 && ! command -v "podman" >/dev/null 2>&1; then
  echo "Error: Neither Docker nor Podman found. Please install one of them."
  exit 1
fi

# Build docker image (corrected Dockerfile path and quoting)
RUNNER=$(command -v podman || command -v docker)  # Use whichever is available


$RUNNER run -d -p 1337:1337 \
  --network=kong-net \
  -e "TOKEN_SECRET=${DATABASE_PASSWORD}" \
  -e "NODE_ENV=development" \
  --name konga \
  pantsel/konga
