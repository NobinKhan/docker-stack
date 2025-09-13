#!/bin/bash

# Start the mini server in the background
python /app/mini_server.py &

# Start the ping loop in the background
/app/ping-loop.sh &

# Start the Celery worker in the background
celery --app saleor.celeryconf:app beat --scheduler saleor.schedulers.schedulers.DatabaseScheduler &

# Wait for all background processes to finish
wait -n
