from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from services.common.mlflow_utils import configure_mlflow_env
from services.serving.app import inference

logger = get_logger(__name__)


def main() -> None:
    configure_logging()
    settings = get_settings()
    configure_mlflow_env(settings)

    if inference.USE_RAY_SERVE:
        import ray
        from ray import serve

        ray.init(ignore_reinit_error=True)
        serve.start(detached=True)
        serve.run(inference.deployment())
        logger.info("Ray Serve running with canary split %.2f", settings.canary_split)
    else:
        import uvicorn

        inference.init_fallback_service()
        logger.info("Ray Serve disabled; starting FastAPI app locally")
        uvicorn.run(
            "services.serving.app.inference:app",
            host="0.0.0.0",  # noqa: S104 - dev server binding
            port=8000,
            log_level="info",
        )


if __name__ == "__main__":
    main()
