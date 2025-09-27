#!/usr/bin/env bash
set -euo pipefail

echo "Running smoke test"
poetry run python scripts/generate_synthetic_data.py
poetry run python services/model_training/train.py
echo "✓ smoke completed"
