import argparse
import requests

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)


def should_rollback(threshold: float = 5.0) -> bool:
    settings = get_settings()
    resp = requests.get(
        f"{settings.prometheus_endpoint}/api/v1/query",
        params={"query": 'sum(increase(serving_app_request_exceptions_total{model_variant="canary"}[5m]))'},
        timeout=5,
    )
    resp.raise_for_status()
    data = resp.json().get("data", {}).get("result", [])
    return any(float(item["value"][1]) > threshold for item in data)


def perform_rollback() -> None:
    logger.warning("Rollback triggered - demoting canary and restoring baseline (stub).")


def main() -> None:
    configure_logging()
    if should_rollback():
        perform_rollback()
    else:
        logger.info("No rollback needed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--confirm", action="store_true", help="Ack manual invocation")
    parser.parse_args()
    main()
