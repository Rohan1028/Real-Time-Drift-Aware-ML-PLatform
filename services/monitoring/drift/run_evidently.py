from __future__ import annotations

import json
from pathlib import Path

import pandas as pd
from evidently.metric_preset import DataDriftPreset
from evidently.report import Report

from services.common.logging import configure_logging, get_logger

logger = get_logger(__name__)
REPORT_DIR = Path("services/monitoring/drift/reports")


def load_data() -> tuple[pd.DataFrame, pd.DataFrame]:
    ref = pd.read_csv("data/sample/events.csv", parse_dates=["event_ts"])
    live = ref.sample(frac=1.0, replace=True).assign(
        transaction_amount=lambda df: df.transaction_amount * 1.1
    )
    return ref, live


def generate_report() -> None:
    ref, live = load_data()
    report = Report(metrics=[DataDriftPreset()])
    report.run(reference_data=ref, current_data=live)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    html_path = REPORT_DIR / "latest.html"
    json_path = REPORT_DIR / "latest.json"
    report.save_html(html_path)
    json_path.write_text(json.dumps(report.as_dict(), indent=2), encoding="utf-8")
    logger.info("Drift report written to %s and %s", html_path, json_path)


def main() -> None:
    configure_logging()
    generate_report()


if __name__ == "__main__":
    main()
