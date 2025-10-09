from datetime import datetime, timezone

import pytest

from services.common.data import SyntheticEventGenerator
from services.common.schemas import FeatureVector, InferenceRequest
from services.serving.app.canary import CanaryDecision
from services.serving.app.metrics import REQUEST_COUNTER


@pytest.mark.integration
@pytest.mark.asyncio
async def test_inference_pipeline(monkeypatch):
    from types import SimpleNamespace

    from ray import serve as ray_serve

    def _passthrough_deployment(*args, **kwargs):
        def decorator(cls):
            return SimpleNamespace(func_or_class=cls, bind=lambda *a, **kw: cls)

        return decorator

    monkeypatch.setattr(ray_serve, "ingress", lambda app: (lambda cls: cls))
    monkeypatch.setattr(ray_serve, "deployment", _passthrough_deployment)
    from services.serving.app import inference

    gen = SyntheticEventGenerator(seed=1, drift=None)
    event = gen.sample(user_id="user-123").model_copy(
        update={"event_ts": datetime(2024, 1, 1, tzinfo=timezone.utc)}
    )
    request = InferenceRequest(user_id=event.user_id, event=event)

    shadow_calls = []

    class StubFeatureService:
        def fetch(self, _event):
            return FeatureVector(
                user_id=_event.user_id,
                transaction_amount=_event.transaction_amount,
                amount_zscore=_event.transaction_amount / 100,
                country_onehot=None,
                device_onehot=None,
                event_ts=_event.event_ts,
            )

    class StubModel:
        def predict_proba(self, frame):
            return [[0.6, 0.4]]

    class StubShadow:
        def __init__(self, _model):
            self.model = _model

        async def submit(self, payload):
            shadow_calls.append(payload)

    class StubCanary:
        def choose(self):
            return CanaryDecision(variant="baseline", probability=1.0)

    monkeypatch.setattr(inference, "FeatureService", lambda: StubFeatureService())
    monkeypatch.setattr(inference, "ShadowInvoker", lambda model: StubShadow(model))
    monkeypatch.setattr(inference, "CanaryStrategy", StubCanary)
    monkeypatch.setattr(inference, "load_model", lambda _: StubModel())
    monkeypatch.setattr("services.serving.app.model_loader.load_model", lambda _: StubModel())

    REQUEST_COUNTER.clear()
    deployment_cls = inference.InferenceDeployment.func_or_class
    deployment = deployment_cls()

    response = await deployment.predict(request)

    assert response.user_id == request.user_id
    assert response.canary_variant == "baseline"
    assert 0.0 <= response.score <= 1.0

    samples = REQUEST_COUNTER.collect()[0].samples
    baseline_samples = [
        sample.value
        for sample in samples
        if sample.labels.get("model_variant") == "baseline" and sample.name.endswith("_total")
    ]
    assert baseline_samples and baseline_samples[0] == pytest.approx(1.0)
    assert shadow_calls and shadow_calls[0]["transaction_amount"] == pytest.approx(
        event.transaction_amount
    )
