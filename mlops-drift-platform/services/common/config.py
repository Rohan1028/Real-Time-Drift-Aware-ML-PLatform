from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    env: str = Field(default="local", alias="ENV")
    kafka_brokers: str = Field(default="localhost:9092", alias="REDPANDA_BROKERS")
    event_topic: str = Field(default="transactions", alias="EVENT_TOPIC")
    feast_repo_path: str = Field(default="services/feature_service/feast_repo", alias="FEAST_REPO_PATH")
    mlflow_tracking_uri: str = Field(default="http://localhost:5000", alias="MLFLOW_TRACKING_URI")
    mlflow_registry_uri: str = Field(default="http://localhost:5000", alias="MLFLOW_REGISTRY_URI")
    minio_endpoint: str = Field(default="http://localhost:9000", alias="MINIO_ENDPOINT")
    minio_access_key: str = Field(default="minio", alias="MINIO_ACCESS_KEY")
    minio_secret_key: str = Field(default="minio123", alias="MINIO_SECRET_KEY")
    minio_bucket: str = Field(default="mlops-demo", alias="MINIO_BUCKET")
    redis_host: str = Field(default="localhost", alias="REDIS_HOST")
    redis_port: int = Field(default=6379, alias="REDIS_PORT")
    postgres_host: str = Field(default="localhost", alias="POSTGRES_HOST")
    postgres_port: int = Field(default=5432, alias="POSTGRES_PORT")
    postgres_db: str = Field(default="mlflow", alias="POSTGRES_DB")
    postgres_user: str = Field(default="mlflow", alias="POSTGRES_USER")
    postgres_password: str = Field(default="mlflow", alias="POSTGRES_PASSWORD")
    canary_split: float = Field(default=0.2, alias="CANARY_SPLIT")
    shadow_enabled: bool = Field(default=True, alias="SHADOW_ENABLED")
    prometheus_endpoint: str = Field(default="http://localhost:9090", alias="PROMETHEUS_ENDPOINT")
    otlp_endpoint: str = Field(default="http://localhost:4317", alias="OTLP_ENDPOINT")

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
