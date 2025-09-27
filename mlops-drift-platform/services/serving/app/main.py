import ray
from ray import serve

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from .inference import deployment

logger = get_logger(__name__)


def main() -> None:
    configure_logging()
    settings = get_settings()
    ray.init(address="auto", ignore_reinit_error=True)
    serve.start(detached=True)
    serve.run(deployment())
    logger.info("Ray Serve running with canary split %.2f", settings.canary_split)
    import uvicorn
    from fastapi import FastAPI

    # For local run, spin up FastAPI pointing to Ray Serve ingress.
    app = FastAPI()

    @app.get("/health")
    async def health():  # pragma: no cover
        return {"status": "ok"}

    uvicorn.run("services.serving.app.inference:app", host="0.0.0.0", port=8000, log_level="info")


if __name__ == "__main__":
    main()
