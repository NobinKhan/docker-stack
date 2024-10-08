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

CONTAINER_IMAGE="getmeili/meilisearch:v1.10.2"
CONTAINER_NAME="meilisearch"
CONTAINER_PORT="7700"
HOST_PORT="7700"
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

CONTAINER_STATE=$(echo "$CONTAINER_INSPECT" | jq -r '.[].Name' 2>&1)
if [[ $CONTAINER_STATE == "$CONTAINER_NAME""_data" ]]; then
  echo "Container $CONTAINER_NAME Was Removed."
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

# Start the container
CONTAINER_ID=$($RUNNER run \
  --rm \
  --detach \
  --network $NETWORK_NAME \
  --name $CONTAINER_NAME \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --env MEILI_MASTER_KEY=${MEILI_MASTER_KEY} \
  --volume meili-search:/data.ms \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi
