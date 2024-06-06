#!/bin/bash

# Load environment variables
source .env

# Confirm Docker/Podman availability
if ! command -v "docker" >/dev/null 2>&1 && ! command -v "podman" >/dev/null 2>&1; then
  echo "Error: Neither Docker nor Podman found. Please install one of them."
  exit 1
fi

# Build docker image (corrected Dockerfile path and quoting)
RUNNER=$(command -v podman || command -v docker)  # Use whichever is available

CONTAINER_IMAGE="stalwartlabs/mail-server:latest"
CONTAINER_NAME="stalwart-mail"

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

# Start the container
CONTAINER_ID=$($RUNNER run \
  --rm \
  -ti \
  --detach \
  --name $CONTAINER_NAME \
  -p 443:443 -p 8080:8080 \
  -p 25:25 -p 587:587 -p 465:465 \
  -p 143:143 -p 993:993 -p 4190:4190 \
  -p 110:110 -p 995:995 \
  --volume /home/nobin/mail_server:/opt/stalwart-mail \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi
