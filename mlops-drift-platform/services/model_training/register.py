import mlflow
from mlflow.tracking import MlflowClient

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)


def register() -> None:
    configure_logging()
    settings = get_settings()
    mlflow.set_tracking_uri(settings.mlflow_tracking_uri)
    client = MlflowClient()
    runs = client.search_runs(experiment_ids=["0"], order_by=["attributes.start_time DESC"], max_results=1)
    if not runs:
        raise SystemExit("No runs found to register.")
    run = runs[0]
    model_name = "fraud-detector"
    mv = client.create_model_version(name=model_name, source=f"{run.info.artifact_uri}/model", run_id=run.info.run_id)
    client.set_registered_model_alias(name=model_name, alias="Staging", version=mv.version)
    logger.info("Registered model version %s in Staging", mv.version)


if __name__ == "__main__":
    register()
