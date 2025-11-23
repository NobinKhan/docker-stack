#!/bin/bash

IP="123.63.5.9"
PORT="5564"
MAX_WAIT=60      # total wait time in seconds
INTERVAL=10      # check every 10 seconds

echo "Checking 9P server at $IP:$PORT"

elapsed=0

while [ $elapsed -lt $MAX_WAIT ]; do
    if nc -z -w2 $IP $PORT; then
        echo "✔ Zerofs 9P server is running on tcp!"

        # -------------------------
        # SUCCESS COMMANDS HERE
        # -------------------------
        sudo mount -t 9p -o trans=tcp,port=5564,version=9p2000.L 168.119.100.234 /container-data

        exit 0
    else
        echo "Zerofs 9P server not reachable... retrying in $INTERVAL seconds"
    fi

    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
done

echo "❌ 9P server did NOT start after $MAX_WAIT seconds."

# -------------------------
# FAILURE COMMANDS HERE
# -------------------------
echo "Running failure commands..."
curl -sSfL https://sh.zerofs.net | sh
zerofs run --config /etc/zerofs/zerofs.toml
sleep 5s
sudo mount -t 9p -o trans=tcp,port=5564,version=9p2000.L 168.119.100.234 /container-data
exit 0
