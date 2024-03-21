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

CONTAINER_IMAGE="getmeili/meilisearch:v1.7.2"
CONTAINER_NAME="meilisearch"
CONTAINER_PORT="7700"
HOST_PORT="7700"

$RUNNER pull $CONTAINER_IMAGE
$RUNNER kill $CONTAINER_NAME && $RUNNER rm $CONTAINER_NAME
CONTAINER_ID=$($RUNNER run \
  --network=kong-net \
  --rm \
  --detach \
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
