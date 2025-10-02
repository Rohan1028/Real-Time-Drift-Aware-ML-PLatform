#!/bin/bash

# After Install Hook
set -e

echo "Running after install hook..."

cd /opt/mlops-platform

# Install Python dependencies if pyproject.toml exists
if [ -f "pyproject.toml" ]; then
    echo "Installing Python dependencies..."
    poetry install --no-dev --no-interaction
fi

# Create Docker Compose file if it doesn't exist
if [ ! -f "docker-compose.yml" ]; then
    echo "Creating Docker Compose configuration..."
    cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  serving:
    build:
      context: ./services/serving
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - REDIS_ENDPOINT=${REDIS_ENDPOINT}
      - POSTGRES_ENDPOINT=${POSTGRES_ENDPOINT}
      - KAFKA_BOOTSTRAP_SERVERS=${KAFKA_BOOTSTRAP_SERVERS}
    volumes:
      - ./models:/opt/models
    restart: unless-stopped

  mlflow:
    image: python:3.11-slim
    command: >
      bash -c "
        pip install mlflow psycopg2-binary &&
        mlflow server 
        --backend-store-uri postgresql://mlops:${POSTGRES_PASSWORD}@${POSTGRES_ENDPOINT}/mlops
        --default-artifact-root s3://${ML_BUCKET_NAME}/mlflow
        --host 0.0.0.0
        --port 5000
      "
    ports:
      - "5000:5000"
    environment:
      - MLFLOW_S3_ENDPOINT_URL=https://s3.${AWS_REGION}.amazonaws.com
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana
    restart: unless-stopped

volumes:
  grafana-storage:
EOF
fi

# Create Prometheus configuration
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'serving'
    static_configs:
      - targets: ['serving:8000']
    metrics_path: '/metrics'
    
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

echo "After install hook completed successfully"



