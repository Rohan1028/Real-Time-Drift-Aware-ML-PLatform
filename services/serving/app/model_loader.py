from functools import lru_cache
from typing import Any

import mlflow.pyfunc

from services.common.logging import get_logger

logger = get_logger(__name__)


@lru_cache(maxsize=4)
def load_model(model_uri: str) -> Any:
    logger.info("Loading model from %s", model_uri)
    return mlflow.pyfunc.load_model(model_uri=model_uri)


def staging_model_uri() -> str:
    return "models:/fraud-detector/Staging"
