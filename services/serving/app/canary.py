import random
from dataclasses import dataclass

from services.common.config import get_settings


@dataclass
class CanaryDecision:
    variant: str
    probability: float


class CanaryStrategy:
    def __init__(self, split: float | None = None) -> None:
        settings = get_settings()
        self.split = split if split is not None else settings.canary_split
        self.random = random.Random(42)  # noqa: S311 - deterministic test-friendly RNG

    def choose(self) -> CanaryDecision:
        value = self.random.random()
        if value < self.split:
            return CanaryDecision(variant="canary", probability=self.split)
        return CanaryDecision(variant="baseline", probability=1 - self.split)
