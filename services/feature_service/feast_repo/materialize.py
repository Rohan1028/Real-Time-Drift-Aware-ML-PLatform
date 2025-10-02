from datetime import datetime, timedelta

from feast import FeatureStore

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)


def materialize() -> None:
    configure_logging()
    settings = get_settings()
    store = FeatureStore(repo_path=settings.feast_repo_path)
    end = datetime.utcnow()
    start = end - timedelta(days=1)
    logger.info("Materializing Feast features from %s to %s", start.isoformat(), end.isoformat())
    store.materialize(start_date=start, end_date=end)


if __name__ == "__main__":
    materialize()
