from __future__ import annotations

import datetime as dt
import random
from typing import Dict, Iterable, Iterator, List, Optional
from uuid import uuid4

from .schemas import Event


class SyntheticEventGenerator:
    """Deterministic-ish generator for incoming transaction events."""

    COUNTRIES: List[str] = ["US", "CA", "GB", "DE", "FR", "IN", "BR"]
    DEVICES: List[str] = ["ios", "android", "web"]

    def __init__(self, seed: int = 42, drift: Optional[float] = None) -> None:
        self.random = random.Random(seed)
        self.drift = drift or 0.0

    def sample(self, user_id: Optional[str] = None) -> Event:
        amount = abs(self.random.gauss(80, 40))
        if self.drift:
            amount *= 1 + self.drift
        return Event(
            event_id=uuid4().hex[:26],
            user_id=user_id or f"user-{self.random.randint(1, 500):03d}",
            transaction_amount=round(amount, 2),
            country=self.random.choice(self.COUNTRIES),
            device=self.random.choice(self.DEVICES),
            event_ts=dt.datetime.utcnow().replace(tzinfo=dt.timezone.utc),
            label=int(self.random.random() < self._fraud_probability(amount)),
        )

    def stream(self, batch_size: int = 1_000) -> Iterator[Event]:
        for _ in range(batch_size):
            yield self.sample()

    def _fraud_probability(self, amount: float) -> float:
        base = 0.02
        if amount > 300:
            base += 0.08
        return min(base, 0.5)


def events_to_dicts(events: Iterable[Event]) -> List[Dict[str, object]]:
    return [event.model_dump(mode="json") for event in events]
