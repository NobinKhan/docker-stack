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

CONTAINER_IMAGE="dpage/pgadmin4:latest"
CONTAINER_NAME="pgadmin"
CONTAINER_PORT="80"
HOST_PORT="5050"

$RUNNER pull $CONTAINER_IMAGE
$RUNNER kill $CONTAINER_NAME && $RUNNER rm $CONTAINER_NAME

$RUNNER run \
  --rm \
  --detach \
  --name $CONTAINER_NAME \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --env PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL} \
  --env PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD} \
  --volume pgadmin_data:/var/lib/pgadmin \
  $CONTAINER_IMAGE

echo "${CONTAINER_NAME}"