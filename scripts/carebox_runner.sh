#!/usr/bin/env sh

echo "carebox backend starting..."
sleep 5
cd ~/project/carebox-version1
source venv/bin/activate

python manage.py runserver 0.0.0.0:8000 >> /home/carebox/logs/carebox_django.log 2>&1
