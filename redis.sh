#!/bin/bash

# set -e  # Exit on error

# Load environment variables
source .env

# Confirm Docker/Podman availability
if ! command -v "docker" >/dev/null 2>&1 && ! command -v "podman" >/dev/null 2>&1; then
  echo "Error: Neither Docker nor Podman found. Please install one of them."
  exit 1
fi

# Build docker image (corrected Dockerfile path and quoting)
RUNNER=$(command -v podman || command -v docker)  # Use whichever is available

CONTAINER_IMAGE="redis/redis-stack:7.2.0-v10"
CONTAINER_NAME="redis_stack"
CONTAINER_PORT="6379"
HOST_PORT="6379"

$RUNNER pull $CONTAINER_IMAGE

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

CONTAINER_STATE=$(echo "$CONTAINER_INSPECT" | jq -r '.[].Name' 2>&1)
if [[ $CONTAINER_STATE == "$CONTAINER_NAME""_data" ]]; then
  echo "Container $CONTAINER_NAME Was Removed."
fi

CONTAINER_ID=$($RUNNER run \
  --rm \
  --detach \
  --name $CONTAINER_NAME \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --publish 6370:8001 \
  --env MEILI_MASTER_KEY=${MEILI_MASTER_KEY} \
  --volume redis-stack:/data \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi
