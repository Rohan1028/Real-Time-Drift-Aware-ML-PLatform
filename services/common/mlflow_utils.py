from __future__ import annotations

import os

from services.common.config import Settings


def configure_mlflow_env(settings: Settings) -> None:
    """Ensure MLflow can talk to the MinIO-backed S3 endpoint."""
    os.environ.setdefault("MLFLOW_S3_ENDPOINT_URL", settings.minio_endpoint)
    os.environ.setdefault("AWS_ACCESS_KEY_ID", settings.minio_access_key)
    os.environ.setdefault("AWS_SECRET_ACCESS_KEY", settings.minio_secret_key)
    os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
