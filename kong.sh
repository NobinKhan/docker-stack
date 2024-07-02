#!/bin/bash

# set -e  # Exit on error

# Load environment variables
source .env

# Confirm Docker/Podman availability
if ! command -v "podman" >/dev/null 2>&1 && ! command -v "docker" >/dev/null 2>&1; then
  echo "Error: Neither Docker nor Podman found. Please install one of them."
  exit 1
fi

# Build docker image (corrected Dockerfile path and quoting)
RUNNER=$(command -v podman || command -v docker)  # Use whichever is available

CONTAINER_IMAGE="kong:3.7.0"
CONTAINER_NAME="kong-gateway"
CONTAINER_PORT="5432"
HOST_PORT="5432"
NETWORK_NAME="Project_Network"

$RUNNER pull $CONTAINER_IMAGE

# Check if the container exists
CONTAINER_INSPECT=$("$RUNNER" inspect "$CONTAINER_NAME" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "Container "$CONTAINER_NAME" not found."
else
  CONTAINER_STATE=$(echo "$CONTAINER_INSPECT" | jq -r '.[].State.Status' 2>&1)

  if [ "$CONTAINER_STATE" = "null" ]; then
    echo "Failed to retrieve container status."

  elif [[ "$CONTAINER_STATE" == "running" ]]; then
    # Kill the container if running
    $RUNNER kill "$CONTAINER_NAME" && $RUNNER rm "$CONTAINER_NAME"
    echo "Container $CONTAINER_NAME stopped & removed."

  elif [[ "$CONTAINER_STATE" == "created" ]]; then
    # Remove the container if created
    $RUNNER rm "$CONTAINER_NAME"
    echo "Container $CONTAINER_NAME removed."

  else
    echo "Container "$CONTAINER_NAME" status: $CONTAINER_STATE"
  fi
fi

# Check if network exists
NETWORK_INSPECT=$("$RUNNER" network inspect "$NETWORK_NAME" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "Network "$NETWORK_NAME" not found."
  echo "Creating network..."
  $RUNNER network create "$NETWORK_NAME"
else
  echo "Network "$NETWORK_NAME" found."
fi

$RUNNER run --rm --network=$NETWORK_NAME \
 -e "KONG_DATABASE=postgres" \
 -e "KONG_PG_HOST=postgresql" \
 -e "KONG_PG_PASSWORD=nobinpgpass" \
kong:3.7.0 kong migrations bootstrap

# Start the container
CONTAINER_ID=$($RUNNER run \
  --rm \
  --detach \
  --network $NETWORK_NAME \
  --name $CONTAINER_NAME \
  --env "KONG_DATABASE=postgres" \
  --env "KONG_PG_HOST=postgresql" \
  --env "KONG_PG_USER=kong" \
  --env "KONG_PG_PASSWORD=nobinpgpass" \
  --env "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  --env "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  --env "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  --env "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  --env "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
  --env "KONG_ADMIN_GUI_URL=http://localhost:8002" \
  --publish 8000:8000 \
  --publish 8443:8443 \
  --publish 127.0.0.1:8001:8001 \
  --publish 127.0.0.1:8002:8002 \
  --publish 127.0.0.1:8444:8444 \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi
