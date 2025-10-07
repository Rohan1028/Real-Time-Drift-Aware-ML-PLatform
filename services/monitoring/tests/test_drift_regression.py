from pathlib import Path

import pytest

from services.monitoring.drift.run_evidently import generate_report
from services.monitoring.drift.validate_report import validate_report


@pytest.mark.regression
def test_drift_report_with_reference_dataset(tmp_path, monkeypatch):
    repo_root = Path.cwd()
    ref_path = repo_root / "data" / "sample" / "drift_reference.csv"
    cur_path = repo_root / "data" / "sample" / "drift_current.csv"

    monkeypatch.setenv("DRIFT_REFERENCE_PATH", str(ref_path))
    monkeypatch.setenv("DRIFT_CURRENT_PATH", str(cur_path))
    monkeypatch.setenv("DRIFT_FAIL_ON_DATASET", "false")
    monkeypatch.setenv("DRIFT_P_VALUE_THRESHOLD", "0.0")

    json_path = generate_report(report_dir=tmp_path)
    validate_report(report_path=json_path)
