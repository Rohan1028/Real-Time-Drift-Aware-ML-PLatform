import json
import time

from kafka import KafkaConsumer

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from services.common.schemas import Event

try:
    from feast import FeatureStore
except ImportError:  # pragma: no cover
    FeatureStore = None  # type: ignore

logger = get_logger(__name__)


def main() -> None:
    configure_logging()
    settings = get_settings()
    consumer = KafkaConsumer(
        settings.event_topic,
        bootstrap_servers=settings.kafka_brokers,
        value_deserializer=lambda m: json.loads(m.decode("utf-8")),
        enable_auto_commit=True,
        auto_offset_reset="latest",
        consumer_timeout_ms=1000,
    )
    store = FeatureStore(repo_path=settings.feast_repo_path)
    logger.info("Streaming events into Feast online store...")
    while True:
        for message in consumer:
            event = Event(**message.value)
            store.write_to_online_store(
                feature_view_name="transaction_features",
                entity_rows=[{"user": event.user_id}],
                feature_rows=[
                    {"transaction_amount": event.transaction_amount, "label": event.label or 0}
                ],
            )
        time.sleep(1.0)


if __name__ == "__main__":
    main()
