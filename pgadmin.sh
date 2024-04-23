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

CONTAINER_IMAGE="dpage/pgadmin4:8.5"
CONTAINER_NAME="pgadmin"
CONTAINER_PORT="80"
HOST_PORT="5050"

$RUNNER pull $CONTAINER_IMAGE

CONTAINER_STATE=$("$RUNNER" inspect -f '{{.State.Status}}' "$CONTAINER_NAME")

if [[ "$CONTAINER_STATE" == "running" ]]; then
  # Kill the container if running
  $RUNNER kill "$CONTAINER_NAME" && $RUNNER rm "$CONTAINER_NAME"
  echo "Container $CONTAINER_NAME stopped & removed."

elif [[ "$CONTAINER_STATE" == "created" ]]; then
  # Remove the container if created
  $RUNNER rm "$CONTAINER_NAME"
  echo "Container $CONTAINER_NAME removed."
fi


CONTAINER_ID=$($RUNNER run \
  --rm \
  --detach \
  --name $CONTAINER_NAME \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --env PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL} \
  --env PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD} \
  --volume pgadmin_data:/var/lib/pgadmin \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi
