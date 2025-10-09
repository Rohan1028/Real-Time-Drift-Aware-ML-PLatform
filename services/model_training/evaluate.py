import json
from pathlib import Path

import mlflow
from mlflow.tracking import MlflowClient

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from services.common.mlflow_utils import configure_mlflow_env

logger = get_logger(__name__)


def evaluate() -> None:
    configure_logging()
    settings = get_settings()
    configure_mlflow_env(settings)
    mlflow.set_tracking_uri(settings.mlflow_tracking_uri)
    client = MlflowClient()
    metrics_path = Path("services/model_training/latest_metrics.json")
    if not metrics_path.exists():
        raise SystemExit("Candidate metrics not found. Run train step first.")
    candidate_metrics = json.loads(metrics_path.read_text())
    try:
        prod_model = client.get_model_version_by_alias("fraud-detector", "Production")
        prod_run = client.get_run(prod_model.run_id)
        prod_auc = float(prod_run.data.metrics.get("roc_auc", 0.0))
    except Exception:
        logger.warning("No production model registered; accepting candidate.")
        return
    if candidate_metrics["roc_auc"] + 1e-5 < prod_auc:
        raise SystemExit(f"Candidate AUC {candidate_metrics['roc_auc']:.3f} < prod {prod_auc:.3f}")
    logger.info("Candidate passes gate (%.3f >= %.3f)", candidate_metrics["roc_auc"], prod_auc)


if __name__ == "__main__":
    evaluate()
