#!/usr/bin/env sh
while true; do
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Pinging ${PING_URL}..."
    if curl -fsS ${PING_URL} > /dev/null; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] SUCCESS: Ping to ${PING_URL} succeeded"
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Ping to ${PING_URL} failed (exit code: $?)" >&2
    fi
    sleep 30
done