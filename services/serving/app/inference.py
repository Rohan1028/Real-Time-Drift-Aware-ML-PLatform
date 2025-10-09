from __future__ import annotations

import os
import sys
from typing import Callable

import mlflow
import pandas as pd
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from services.common.mlflow_utils import configure_mlflow_env
from services.common.schemas import InferenceRequest, InferenceResponse
from services.serving.app.canary import CanaryStrategy
from services.serving.app.feature_client import FeatureService
from services.serving.app.metrics import EXCEPTION_COUNTER, REQUEST_COUNTER, REQUEST_LATENCY
from services.serving.app.model_loader import load_model, staging_model_uri
from services.serving.app.shadow import ShadowInvoker

try:
    from ray import serve
except ImportError:  # pragma: no cover - ray optional for local dev
    serve = None  # type: ignore[assignment]

logger = get_logger(__name__)
configure_logging()

_service_provider: Callable[[], InferenceService] | None = None


def _set_service_provider(provider: Callable[[], InferenceService]) -> None:
    global _service_provider
    _service_provider = provider


def _get_service() -> InferenceService:
    if _service_provider is None:
        raise RuntimeError("Inference service not initialized")
    return _service_provider()


def _ray_enabled() -> bool:
    env_override = os.getenv("ENABLE_RAY_SERVE")
    if env_override is not None:
        return env_override.lower() in {"1", "true", "yes"}
    # Default to disabling Ray Serve on Windows where cloudpickle struggles with FastAPI locks.
    return serve is not None and sys.platform != "win32"


app = FastAPI(title="Drift-Aware Inference API", version="0.1.0")
Instrumentator().instrument(app).expose(app)


class InferenceService:
    def __init__(self) -> None:
        settings = get_settings()
        configure_mlflow_env(settings)
        mlflow.set_tracking_uri(settings.mlflow_tracking_uri)
        self.settings = settings
        self.feature_service = FeatureService()
        self.canary = CanaryStrategy()
        self.baseline_model = load_model(staging_model_uri())
        self.canary_model = self.baseline_model  # placeholder for new candidate
        self.shadow = ShadowInvoker(self.baseline_model) if settings.shadow_enabled else None
        logger.info("Inference service ready with split %.2f", settings.canary_split)

    def _predict(self, model, features: pd.DataFrame) -> float:
        return float(model.predict_proba(features)[0][1])

    async def health(self) -> dict[str, str]:
        return {"status": "ok"}

    async def predict(self, request: InferenceRequest) -> InferenceResponse:
        features = self.feature_service.fetch(request.event)
        frame = pd.DataFrame(
            [
                {
                    "transaction_amount": features.transaction_amount,
                    "country": request.event.country,
                    "device": request.event.device,
                    "event_ts": request.event.event_ts,
                }
            ]
        )
        decision = self.canary.choose()
        model = self.canary_model if decision.variant == "canary" else self.baseline_model
        REQUEST_COUNTER.labels(model_variant=decision.variant).inc()
        with REQUEST_LATENCY.labels(model_variant=decision.variant).time():
            try:
                score = self._predict(model, frame)
            except Exception:  # pragma: no cover - metrics and raise
                EXCEPTION_COUNTER.labels(model_variant=decision.variant).inc()
                raise
        if self.shadow:
            await self.shadow.submit(frame.iloc[0].to_dict())
        return InferenceResponse(
            user_id=request.user_id,
            model_version="staging",
            score=score,
            decision="approve" if score < 0.5 else "review",
            canary_variant=decision.variant,
        )


@app.get("/health")
async def health_endpoint() -> dict[str, str]:  # pragma: no cover - simple endpoint
    return await _get_service().health()


@app.post("/predict", response_model=InferenceResponse)
async def predict_endpoint(request: InferenceRequest) -> InferenceResponse:
    return await _get_service().predict(request)


USE_RAY_SERVE = _ray_enabled()

if USE_RAY_SERVE:
    if serve is None:  # pragma: no cover - safety guard
        raise RuntimeError("Ray Serve requested but ray is not installed.")

    @serve.deployment(ray_actor_options={"num_cpus": 1})
    @serve.ingress(app)
    class InferenceDeployment(InferenceService):
        def __init__(self) -> None:
            super().__init__()
            _set_service_provider(lambda: self)

    def deployment():
        return InferenceDeployment.bind()

else:
    _fallback_service: InferenceService | None = None

    def init_fallback_service() -> InferenceService:
        global _fallback_service
        if _fallback_service is None:
            _fallback_service = InferenceDeployment()
        return _fallback_service

    def deployment():  # pragma: no cover - not used without ray
        raise RuntimeError(
            "Ray Serve is disabled on this platform. Set ENABLE_RAY_SERVE=1 to enable."
        )

    class InferenceDeployment(InferenceService):
        func_or_class: type[InferenceDeployment]

        def __init__(self) -> None:
            super().__init__()
            _set_service_provider(lambda: self)

    InferenceDeployment.func_or_class = InferenceDeployment
