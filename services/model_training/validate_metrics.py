from __future__ import annotations

import json
import os
from pathlib import Path

from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)
METRICS_PATH = Path("services/model_training/latest_metrics.json")


def _load_metrics(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Metrics file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def validate_metrics(
    metrics_path: Path | None = None,
    min_auc: float | None = None,
    min_avg_precision: float | None = None,
) -> None:
    """Ensure recently produced model metrics satisfy minimum thresholds."""

    configure_logging()
    target = metrics_path or METRICS_PATH
    metrics = _load_metrics(target)
    auc = float(metrics.get("roc_auc", 0.0))
    avg_precision = float(metrics.get("avg_precision", 0.0))

    auc_threshold = min_auc if min_auc is not None else float(os.getenv("MIN_ROC_AUC", "0.65"))
    ap_threshold = (
        min_avg_precision
        if min_avg_precision is not None
        else float(os.getenv("MIN_AVG_PRECISION", "0.50"))
    )

    logger.info(
        "Validating metrics: roc_auc=%.3f avg_precision=%.3f (thresholds %.3f / %.3f)",
        auc,
        avg_precision,
        auc_threshold,
        ap_threshold,
    )

    if auc < auc_threshold:
        raise SystemExit(f"roc_auc {auc:.3f} below threshold {auc_threshold:.3f}")
    if avg_precision < ap_threshold:
        raise SystemExit(f"avg_precision {avg_precision:.3f} below threshold {ap_threshold:.3f}")


if __name__ == "__main__":
    validate_metrics()
