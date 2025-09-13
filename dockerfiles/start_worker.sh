#!/bin/bash

# Start the mini server in the background
python /app/mini_server.py &

# Start the ping loop in the background
/app/ping-loop.sh &

# Start the Celery worker in the background
celery -A saleor --app=saleor.celeryconf:app worker --loglevel=info -E &

# Wait for all background processes to finish
wait -n
