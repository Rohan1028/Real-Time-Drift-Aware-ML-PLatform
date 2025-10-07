from functools import lru_cache
from typing import Any

import mlflow.pyfunc

from services.common.logging import get_logger

logger = get_logger(__name__)


class ModelLoadError(RuntimeError):
    """Raised when an MLflow model cannot be loaded."""


@lru_cache(maxsize=4)
def load_model(model_uri: str) -> Any:
    logger.info("Loading model from %s", model_uri)
    try:
        return mlflow.pyfunc.load_model(model_uri=model_uri)
    except Exception as exc:  # pragma: no cover - dedicated failure test handles this
        logger.error("Failed to load model from %s: %s", model_uri, exc)
        raise ModelLoadError(f"Unable to load model at {model_uri}") from exc


def staging_model_uri() -> str:
    return "models:/fraud-detector/Staging"
