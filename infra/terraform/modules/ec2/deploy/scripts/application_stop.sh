#!/bin/bash

# Application Stop Hook
set -e

echo "Stopping MLOps Platform services..."

cd /opt/mlops-platform

# Stop services gracefully
docker-compose down --timeout 30

echo "Services stopped successfully"



