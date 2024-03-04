#!/bin/bash

set -e  # Exit on error

ssh carebox@192.168.68.117 "podman kill -a && ./scripts/carebox_project_runner.py"

exit 0
