from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Tuple

import pandas as pd
from evidently.metric_preset import DataDriftPreset
from evidently.report import Report

from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)
REPORT_DIR = Path("services/monitoring/drift/reports")


def _read_dataset(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")
    return pd.read_csv(path, parse_dates=["event_ts"])


def load_data() -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Load reference and current frames for drift analysis.

    Environment variables DRIFT_REFERENCE_PATH and DRIFT_CURRENT_PATH can override
    the default synthetic dataset. This makes it easy to feed fixture data in tests or CI.
    """

    ref_override = os.getenv("DRIFT_REFERENCE_PATH")
    cur_override = os.getenv("DRIFT_CURRENT_PATH")

    if ref_override and cur_override:
        reference_path = Path(ref_override)
        current_path = Path(cur_override)
        try:
            reference = _read_dataset(reference_path)
            current = _read_dataset(current_path)
        except FileNotFoundError as exc:
            raise RuntimeError(f"Failed to read configured drift datasets: {exc}") from exc
        except Exception as exc:  # pragma: no cover - guardrail for CSV parse errors
            raise RuntimeError(f"Unable to parse drift datasets: {exc}") from exc
        return reference, current

    default_path = Path("data/sample/events.csv")
    if not default_path.exists():
        raise RuntimeError(f"Reference dataset missing at {default_path}")

    reference = pd.read_csv(default_path, parse_dates=["event_ts"])
    current = reference.sample(frac=1.0, replace=True).assign(
        transaction_amount=lambda df: df.transaction_amount * 1.1
    )
    return reference, current


def generate_report(report_dir: Path | None = None) -> Path:
    reference, current = load_data()
    report = Report(metrics=[DataDriftPreset()])
    report.run(reference_data=reference, current_data=current)

    target_dir = report_dir or REPORT_DIR
    target_dir.mkdir(parents=True, exist_ok=True)

    html_path = target_dir / "latest.html"
    json_path = target_dir / "latest.json"
    report.save_html(str(html_path))
    json_payload = report.as_dict()
    json_path.write_text(json.dumps(json_payload, indent=2, default=str), encoding="utf-8")
    logger.info("Drift report written to %s and %s", html_path, json_path)
    return json_path


def main() -> None:
    configure_logging()
    generate_report()


if __name__ == "__main__":
    main()
