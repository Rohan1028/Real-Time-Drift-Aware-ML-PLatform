#!/bin/bash

# Application Start Hook
set -e

echo "Starting MLOps Platform services..."

cd /opt/mlops-platform

# Start services with Docker Compose
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check service health
echo "Checking service health..."

# Check serving API
for i in {1..30}; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "Serving API is healthy"
        break
    fi
    echo "Waiting for serving API... ($i/30)"
    sleep 10
done

# Check MLflow
for i in {1..30}; do
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo "MLflow is healthy"
        break
    fi
    echo "Waiting for MLflow... ($i/30)"
    sleep 10
done

# Check Grafana
for i in {1..30}; do
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "Grafana is healthy"
        break
    fi
    echo "Waiting for Grafana... ($i/30)"
    sleep 10
done

echo "All services started successfully"



