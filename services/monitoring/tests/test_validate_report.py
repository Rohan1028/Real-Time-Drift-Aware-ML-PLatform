import json
from pathlib import Path

import pytest

from services.monitoring.drift.validate_report import validate_report


def _write_report(path: Path, *, dataset_drift: bool, p_value: float) -> None:
    payload = {
        "metrics": [
            {
                "result": {
                    "dataset_drift": dataset_drift,
                    "p_value": p_value,
                    "drift_score": 0.0,
                }
            }
        ]
    }
    path.write_text(json.dumps(payload), encoding="utf-8")


def test_validate_report_pass(tmp_path):
    report_path = tmp_path / "report.json"
    _write_report(report_path, dataset_drift=False, p_value=0.2)
    validate_report(report_path=report_path)


def test_validate_report_fails_on_drift(tmp_path):
    report_path = tmp_path / "report.json"
    _write_report(report_path, dataset_drift=True, p_value=0.2)
    with pytest.raises(SystemExit):
        validate_report(report_path=report_path)


def test_validate_report_fails_on_low_pvalue(tmp_path, monkeypatch):
    report_path = tmp_path / "report.json"
    _write_report(report_path, dataset_drift=False, p_value=0.01)
    monkeypatch.setenv("DRIFT_FAIL_ON_DATASET", "false")
    with pytest.raises(SystemExit):
        validate_report(report_path=report_path)
