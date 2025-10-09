from typing import Dict

from feast import FeatureStore

from services.common.config import get_settings
from services.common.logging import get_logger
from services.common.schemas import Event, FeatureVector

logger = get_logger(__name__)


class FeatureService:
    def __init__(self) -> None:
        settings = get_settings()
        self.store = FeatureStore(repo_path=settings.feast_repo_path)

    def fetch(self, event: Event) -> FeatureVector:
        try:
            features: Dict[str, Dict[str, float]] = self.store.get_online_features(
                features=[
                    f"transaction_features:{name}" for name in ("transaction_amount", "label")
                ],
                entity_rows=[{"user_id": event.user_id}],
            ).to_dict()
        except Exception as exc:  # pragma: no cover - fallback path
            logger.warning("Falling back to raw features due to: %s", exc)
            features = {
                "transaction_amount": [event.transaction_amount],
                "label": [event.label or 0],
            }
        return FeatureVector(
            user_id=event.user_id,
            transaction_amount=event.transaction_amount,
            event_ts=event.event_ts,
            amount_zscore=float(features.get("transaction_amount", [event.transaction_amount])[0]),
            country_onehot=None,
            device_onehot=None,
        )
