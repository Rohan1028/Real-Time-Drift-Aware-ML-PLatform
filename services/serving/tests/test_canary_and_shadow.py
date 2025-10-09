from datetime import datetime, timezone

import pytest

from services.common.schemas import Event
from services.serving.app.canary import CanaryDecision, CanaryStrategy
from services.serving.app.feature_client import FeatureService
from services.serving.app.shadow import ShadowInvoker


class DummyStore:
    def __init__(self, data):
        self._data = data

    def get_online_features(self, *_, **__):
        class _Wrapper:
            def __init__(self, payload):
                self._payload = payload

            def to_dict(self):
                return self._payload

        return _Wrapper(self._data)


@pytest.fixture()
def simple_event():
    return Event(
        event_id="01HQA7F9G4G1YJ2R4D8K2J3A5S",
        user_id="user-1",
        transaction_amount=10.0,
        country="US",
        device="ios",
        event_ts=datetime(2024, 1, 1, tzinfo=timezone.utc),
        label=0,
    )


def test_canary_strategy_split():
    strategy = CanaryStrategy(split=0.7)
    decision = strategy.choose()
    assert isinstance(decision, CanaryDecision)
    assert decision.variant == "canary"
    assert pytest.approx(decision.probability, rel=1e-6) == 0.7


def test_canary_strategy_baseline():
    strategy = CanaryStrategy(split=0.0)
    decision = strategy.choose()
    assert decision.variant == "baseline"
    assert decision.probability == 1.0


@pytest.mark.asyncio
async def test_shadow_invoker_runs_prediction(simple_event):
    calls = []

    class StubModel:
        def predict_proba(self, frame):
            calls.append(frame.to_dict("records"))
            return [[0.6, 0.4]]

    invoker = ShadowInvoker(StubModel())
    await invoker.submit(simple_event.model_dump())
    assert len(calls) == 1
    assert calls[0][0]["transaction_amount"] == pytest.approx(10.0)


def test_feature_service_fetches(monkeypatch, simple_event):
    from services.serving.app import feature_client

    monkeypatch.setattr(
        feature_client,
        "FeatureStore",
        lambda repo_path: DummyStore({"transaction_amount": [0.25], "label": [0]}),
    )
    svc = FeatureService()
    features = svc.fetch(simple_event)
    assert features.amount_zscore == pytest.approx(0.25)
    assert features.transaction_amount == simple_event.transaction_amount


def test_feature_service_fallback(monkeypatch, simple_event):
    from services.serving.app import feature_client

    class BrokenStore(DummyStore):
        def get_online_features(self, *args, **kwargs):
            raise RuntimeError("boom")

    monkeypatch.setattr(
        feature_client, "FeatureStore", lambda repo_path: BrokenStore({"transaction_amount": [0.9]})
    )
    svc = FeatureService()
    features = svc.fetch(simple_event)
    assert features.amount_zscore == pytest.approx(simple_event.transaction_amount)
    assert features.transaction_amount == simple_event.transaction_amount
