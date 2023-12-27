#!/usr/bin/env sh

echo "carebox dramatiq starting..."
sleep 10
cd ~/project/carebox-version1
source venv/bin/activate

python manage.py rundramatiq >> /home/carebox/logs/carebox_dramatiq.log 2>&1
