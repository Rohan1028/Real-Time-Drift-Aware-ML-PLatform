from __future__ import annotations

import json
import time
from typing import Any, Dict

from kafka import KafkaProducer

from services.common.config import get_settings
from services.common.data import SyntheticEventGenerator, events_to_dicts
from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)


def serialize(event: Dict[str, Any]) -> bytes:
    return json.dumps(event, default=str).encode("utf-8")


def main() -> None:
    configure_logging()
    settings = get_settings()
    producer = KafkaProducer(bootstrap_servers=settings.kafka_brokers, value_serializer=serialize)
    generator = SyntheticEventGenerator()
    logger.info("Starting producer loop to %s", settings.kafka_brokers)

    try:
        while True:
            batch = events_to_dicts(generator.stream(batch_size=5))
            for event in batch:
                producer.send(settings.event_topic, value=event, key=event["user_id"].encode("utf-8"))
            producer.flush()
            time.sleep(1.0)
    except KeyboardInterrupt:
        logger.info("Stopping producer...")
    finally:
        producer.flush()
        producer.close()


if __name__ == "__main__":
    main()
