import mlflow
from mlflow.tracking import MlflowClient

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from services.common.mlflow_utils import configure_mlflow_env

logger = get_logger(__name__)


def register() -> None:
    configure_logging()
    settings = get_settings()
    configure_mlflow_env(settings)
    mlflow.set_tracking_uri(settings.mlflow_tracking_uri)
    client = MlflowClient()
    runs = client.search_runs(
        experiment_ids=["0"],
        order_by=["attributes.start_time DESC"],
        max_results=1,
    )
    if not runs:
        raise SystemExit("No runs found to register.")
    run = runs[0]
    model_name = "fraud-detector"
    try:
        client.get_registered_model(model_name)
    except Exception:
        client.create_registered_model(model_name)
    mv = client.create_model_version(
        name=model_name,
        source=f"{run.info.artifact_uri}/model",
        run_id=run.info.run_id,
    )
    client.set_registered_model_alias(name=model_name, alias="Staging", version=mv.version)
    logger.info("Registered model version %s in Staging", mv.version)


if __name__ == "__main__":
    register()
