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


$RUNNER run -d --rm --name kong-database \
 --network=kong-net \
 -p 5432:5432 \
 -e "POSTGRES_USER=${DATABASE_USER}" \
 -e "POSTGRES_DB=kong" \
 -e "POSTGRES_PASSWORD=${DATABASE_PASSWORD}" \
 postgres:16.2-alpine3.19

$RUNNER run --rm --network=kong-net \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database" \
-e "KONG_PG_USER=${DATABASE_USER}" \
-e "KONG_PG_PASSWORD=${DATABASE_PASSWORD}" \
kong/kong-gateway:3.6.1.1 kong migrations bootstrap


$RUNNER run -d --rm --name kong-gateway \
--network=kong-net \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database" \
-e "KONG_PG_USER=${DATABASE_USER}" \
-e "KONG_PG_PASSWORD=${DATABASE_PASSWORD}" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
-e "KONG_ADMIN_GUI_LISTEN=0.0.0.0:8002" \
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
-e KONG_LICENSE_DATA \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8444:8444 \
-p 8002:8002 \
-p 8445:8445 \
-p 8003:8003 \
-p 8004:8004 \
kong/kong-gateway:3.6.1.1