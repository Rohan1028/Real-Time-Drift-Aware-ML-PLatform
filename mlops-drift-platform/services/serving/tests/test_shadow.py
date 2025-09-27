import pandas as pd

from services.serving.app.shadow import ShadowInvoker


class DummyModel:
    def __init__(self) -> None:
        self.calls = 0

    def predict_proba(self, frame: pd.DataFrame):  # type: ignore[override]
        self.calls += 1
        return [[0.4, 0.6]]


def test_shadow_invoker_executes(monkeypatch):
    model = DummyModel()
    invoker = ShadowInvoker(model)
    frame = {"transaction_amount": 10, "country": "US", "device": "ios", "event_ts": "2024-01-01"}
    import asyncio

    asyncio.run(invoker.submit(frame))
    assert model.calls == 1
