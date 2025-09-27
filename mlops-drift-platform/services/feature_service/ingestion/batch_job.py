import os
from pathlib import Path

import pandas as pd

from services.common.config import get_settings
from services.common.data import SyntheticEventGenerator
from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)


def run() -> None:
    configure_logging()
    settings = get_settings()
    output = Path("data/sample/events.parquet")
    generator = SyntheticEventGenerator()
    events = [event.model_dump() for event in generator.stream(batch_size=500)]
    df = pd.DataFrame(events)
    df["created_at"] = pd.Timestamp.utcnow()
    output.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(output, index=False)
    logger.info("Wrote %s rows to %s", len(df), output)
    os.environ.setdefault("FEAST_IS_LOCAL_TEST", "1")


if __name__ == "__main__":
    run()
