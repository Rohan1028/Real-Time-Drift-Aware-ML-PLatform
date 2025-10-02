#!/bin/bash

# Validate Service Hook
set -e

echo "Validating service deployment..."

# Test API endpoint
echo "Testing API endpoint..."
if curl -f http://localhost:8000/health; then
    echo "✓ API health check passed"
else
    echo "✗ API health check failed"
    exit 1
fi

# Test prediction endpoint
echo "Testing prediction endpoint..."
response=$(curl -s -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "event": {
      "transaction_amount": 100.0,
      "country": "US",
      "device": "web",
      "event_ts": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
    }
  }')

if echo "$response" | grep -q "prediction"; then
    echo "✓ Prediction endpoint working"
else
    echo "✗ Prediction endpoint failed"
    echo "Response: $response"
    exit 1
fi

# Test MLflow
echo "Testing MLflow..."
if curl -f http://localhost:5000/health; then
    echo "✓ MLflow health check passed"
else
    echo "✗ MLflow health check failed"
    exit 1
fi

# Test Grafana
echo "Testing Grafana..."
if curl -f http://localhost:3000/api/health; then
    echo "✓ Grafana health check passed"
else
    echo "✗ Grafana health check failed"
    exit 1
fi

echo "All service validation checks passed successfully"



