#!/bin/bash

set -e  # Exit on error

# Load environment variables
source ./scripts/.env

# Confirm Docker/Podman availability
if ! command -v "docker" >/dev/null 2>&1 && ! command -v "podman" >/dev/null 2>&1; then
  echo "Error: Neither Docker nor Podman found. Please install one of them."
  exit 1
fi

# Build docker image (corrected Dockerfile path and quoting)
RUNNER=$(command -v podman || command -v docker)  # Use whichever is available

# Clear all containers and images
$RUNNER kill -a && $RUNNER rm -a

# postgresql
CONTAINER_IMAGE="postgres:16.2-alpine3.19"
CONTAINER_NAME="postgresql"
CONTAINER_PORT="5432"
HOST_PORT="5432"

$RUNNER pull $CONTAINER_IMAGE

CONTAINER_ID=$($RUNNER run \
  --rm \
  --detach \
  --name $CONTAINER_NAME \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --env POSTGRES_USER=${DATABASE_USER} \
  --env POSTGRES_PASSWORD=${DATABASE_PASSWORD} \
  --volume postgresql_data1:/data/postgres \
  --volume postgresql_data2:/var/lib/postgresql/data \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi

# Redis
CONTAINER_IMAGE="redis/redis-stack:7.2.0-v8"
CONTAINER_NAME="redis_stack"
CONTAINER_PORT="6379"
HOST_PORT="6379"

$RUNNER pull $CONTAINER_IMAGE

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

# Meilisearch
CONTAINER_IMAGE="getmeili/meilisearch:v1.6.2"
CONTAINER_NAME="meilisearch"
CONTAINER_PORT="7700"
HOST_PORT="7700"

$RUNNER pull $CONTAINER_IMAGE

CONTAINER_ID=$($RUNNER run \
  --rm \
  --detach \
  --name $CONTAINER_NAME \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --env MEILI_MASTER_KEY=${MEILISEARCH_MASTER_KEY} \
  --volume meili-search:/data.ms \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi

sleep 10

# Carebox
CONTAINER_IMAGE="ghcr.io/careboxdevteam/carebox-backend-cicd:dev_image"
CONTAINER_NAME="carebox"
CONTAINER_PORT="8000"
HOST_PORT="8000"

$RUNNER login --username nobinkhan --password $GHCR_TOKEN ghcr.io
$RUNNER pull $CONTAINER_IMAGE

CONTAINER_ID=$($RUNNER run \
  --detach \
  --name $CONTAINER_NAME \
  --publish 8050:8001 \
  --publish $HOST_PORT:$CONTAINER_PORT \
  --volume carebox_data:/home/nonroot/project/ \
  $CONTAINER_IMAGE)

# Check if the container started successfully
if [[ $? -eq 0 ]]; then
  # Print the success message with the container ID
  echo "Container $CONTAINER_NAME started successfully with ID: $CONTAINER_ID"
else
  echo "Error starting container $CONTAINER_NAME!"
fi

$RUNNER cp ./scripts/.env carebox:/home/nonroot/project/.env
$RUNNER kill $CONTAINER_NAME
sleep 10

$RUNNER start $CONTAINER_NAME
