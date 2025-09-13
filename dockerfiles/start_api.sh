#!/bin/bash

# Start the ping loop in the background
/app/ping-loop.sh &

# Start the api in the background
uvicorn saleor.asgi:application --host=0.0.0.0 --port=8000 --workers=2 --lifespan=off --ws=none --no-server-header --timeout-keep-alive=35 --timeout-graceful-shutdown=30 --limit-max-requests=10000 --log-level=debug &

# Wait for all background processes to finish
wait -n
