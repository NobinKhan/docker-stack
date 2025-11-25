#!/bin/bash

IP="168.119.100.234"
PORT="5564"
MAX_WAIT=60
INTERVAL=10
MOUNT_POINT="/container-data/zerofs-volume"

echo "Checking 9P server at $IP:$PORT"

elapsed=0

while [ $elapsed -lt $MAX_WAIT ]; do
    if nc -z -w2 $IP $PORT; then
        echo "✔ Remote Zerofs 9P server is running!"

        # Trigger automatic mount by accessing the mount point
        mkdir -p "$MOUNT_POINT"
        ls "$MOUNT_POINT" >/dev/null 2>&1

        echo "✓ Mounted remote 9P successfully."
        exit 0
    else
        echo "Remote 9P not reachable → retrying in $INTERVAL seconds..."
    fi

    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
done

echo "❌ Remote Zerofs 9P did NOT respond after $MAX_WAIT seconds."
echo "➡ Starting local Zerofs server instead..."

# Install zerofs if not installed
if ! command -v zerofs >/dev/null 2>&1; then
    curl -sSfL https://sh.zerofs.net | sh
fi

# Start local Zerofs server
nohup zerofs run --config /etc/zerofs/zerofs.toml >/var/log/zerofs.log 2>&1 &
sleep 5

echo "✔ Local Zerofs server started."

# Trigger automount
mkdir -p "$MOUNT_POINT"
ls "$MOUNT_POINT" >/dev/null 2>&1


echo "✔ Mounted local Zerofs fallback."

exit 0