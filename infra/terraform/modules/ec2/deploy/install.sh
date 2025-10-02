#!/bin/bash

# CodeDeploy Install Script for MLOps Platform
set -e

echo "Starting deployment installation..."

# Set environment variables
cd /opt/mlops-platform

# Stop existing services gracefully
echo "Stopping existing services..."
docker-compose down --timeout 30 || true

# Backup current configuration
echo "Backing up current configuration..."
if [ -d ".env.backup" ]; then
    rm -rf .env.backup
fi
if [ -f ".env" ]; then
    cp .env .env.backup
fi

# Extract deployment package (handled by CodeDeploy)
echo "Extracting deployment package..."
# CodeDeploy extracts files to /opt/codedeploy-agent/deployment-root/<deployment-id>/<deployment-group-name>/deployment-archive/

# Copy new application files
echo "Installing new application files..."
cp -r /opt/codedeploy-agent/deployment-root/*/deployment-archive/* /opt/mlops-platform/

# Restore environment configuration
echo "Restoring environment configuration..."
if [ -f ".env.backup" ]; then
    cp .env.backup .env
    rm .env.backup
fi

# Install Python dependencies
echo "Installing Python dependencies..."
if [ -f "pyproject.toml" ]; then
    poetry install --no-dev --no-interaction
fi

# Pull latest Docker images
echo "Pulling latest Docker images..."
docker-compose pull

# Start services
echo "Starting services..."
./start_services.sh

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
sleep 60

# Health check
echo "Performing health check..."
if curl -f http://localhost:8000/health; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed"
    exit 1
fi



