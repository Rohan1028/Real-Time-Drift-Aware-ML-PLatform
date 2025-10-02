#!/bin/bash

# Before Install Hook
set -e

echo "Running before install hook..."

# Update system packages
apt-get update

# Ensure Docker is running
systemctl start docker
systemctl enable docker

# Clean up old Docker images and containers
docker system prune -f

# Create necessary directories
mkdir -p /opt/mlops-platform/logs
mkdir -p /opt/mlops-platform/data
mkdir -p /opt/mlops-platform/models

# Set proper permissions
chown -R ubuntu:ubuntu /opt/mlops-platform
chmod +x /opt/mlops-platform/deploy/*.sh

echo "Before install hook completed successfully"



