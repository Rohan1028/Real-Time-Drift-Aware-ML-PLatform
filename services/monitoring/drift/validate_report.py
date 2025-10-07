from __future__ import annotations

import json
import os
from pathlib import Path

from services.common.logging import configure_logging, get_logger

from .run_evidently import REPORT_DIR

logger = get_logger(__name__)


def _extract_dataset_result(report: dict) -> dict:
    for metric in report.get("metrics", []):
        result = metric.get("result")
        if isinstance(result, dict) and "dataset_drift" in result:
            return result
    raise KeyError("Unable to locate dataset drift metrics in report payload.")


def validate_report(report_path: Path | None = None) -> None:
    """Fail fast if drift exceeds configured thresholds.

    Environment variables:
        DRIFT_FAIL_ON_DATASET = 'true' | 'false' (default true)
        DRIFT_P_VALUE_THRESHOLD = float (default 0.05)
    """

    configure_logging()
    target = report_path or REPORT_DIR / "latest.json"
    if not target.exists():
        raise SystemExit(f"Drift report {target} does not exist.")

    payload = json.loads(target.read_text(encoding="utf-8"))
    result = _extract_dataset_result(payload)
    fail_on_dataset = os.getenv("DRIFT_FAIL_ON_DATASET", "true").lower() == "true"
    p_threshold = float(os.getenv("DRIFT_P_VALUE_THRESHOLD", "0.05"))

    dataset_drift = bool(result.get("dataset_drift"))
    p_value = float(result.get("p_value", 0.0))
    logger.info("Drift summary: dataset_drift=%s p_value=%.4f", dataset_drift, p_value)

    if fail_on_dataset and dataset_drift:
        raise SystemExit("Dataset drift detected and fail flag enabled.")
    if p_value < p_threshold:
        raise SystemExit(
            f"Drift p-value {p_value:.4f} below configured threshold {p_threshold:.4f}"
        )


if __name__ == "__main__":
    validate_report()
