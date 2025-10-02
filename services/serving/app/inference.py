from __future__ import annotations

import pandas as pd
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from ray import serve

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from services.common.schemas import InferenceRequest, InferenceResponse
from .canary import CanaryStrategy
from .feature_client import FeatureService
from .metrics import EXCEPTION_COUNTER, REQUEST_COUNTER, REQUEST_LATENCY
from .model_loader import load_model, staging_model_uri
from .shadow import ShadowInvoker

logger = get_logger(__name__)
configure_logging()
app = FastAPI(title="Drift-Aware Inference API", version="0.1.0")
Instrumentator().instrument(app).expose(app)


@serve.deployment(ray_actor_options={"num_cpus": 1})
@serve.ingress(app)
class InferenceDeployment:
    def __init__(self) -> None:
        settings = get_settings()
        self.feature_service = FeatureService()
        self.canary = CanaryStrategy()
        self.baseline_model = load_model(staging_model_uri())
        self.canary_model = self.baseline_model  # placeholder for new candidate
        self.shadow = ShadowInvoker(self.baseline_model) if settings.shadow_enabled else None
        logger.info("Inference deployment ready with split %.2f", settings.canary_split)

    def _predict(self, model, features: pd.DataFrame) -> float:
        return float(model.predict_proba(features)[0][1])

    @app.get("/health")
    async def health(self) -> dict[str, str]:  # pragma: no cover - simple endpoint
        return {"status": "ok"}

    @app.post("/predict", response_model=InferenceResponse)
    async def predict(self, request: InferenceRequest) -> InferenceResponse:
        features = self.feature_service.fetch(request.event)
        frame = pd.DataFrame([
            {
                "transaction_amount": features.transaction_amount,
                "country": request.event.country,
                "device": request.event.device,
                "event_ts": request.event.event_ts,
            }
        ])
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


def deployment() -> serve.Deployment:
    return InferenceDeployment.bind()
