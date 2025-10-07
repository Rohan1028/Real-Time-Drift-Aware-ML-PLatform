import json
from pathlib import Path

import pytest

from services.model_training.validate_metrics import validate_metrics


def _write_metrics(path: Path, auc: float, ap: float) -> None:
    payload = {"roc_auc": auc, "avg_precision": ap}
    path.write_text(json.dumps(payload), encoding="utf-8")


def test_validate_metrics_pass(tmp_path):
    metrics_path = tmp_path / "metrics.json"
    _write_metrics(metrics_path, auc=0.9, ap=0.8)
    validate_metrics(metrics_path=metrics_path, min_auc=0.7, min_avg_precision=0.6)


def test_validate_metrics_fail_auc(tmp_path):
    metrics_path = tmp_path / "metrics.json"
    _write_metrics(metrics_path, auc=0.5, ap=0.8)
    with pytest.raises(SystemExit):
        validate_metrics(metrics_path=metrics_path, min_auc=0.7, min_avg_precision=0.6)


def test_validate_metrics_fail_ap(tmp_path):
    metrics_path = tmp_path / "metrics.json"
    _write_metrics(metrics_path, auc=0.8, ap=0.3)
    with pytest.raises(SystemExit):
        validate_metrics(metrics_path=metrics_path, min_auc=0.7, min_avg_precision=0.6)


@pytest.mark.regression
def test_validate_metrics_regression_threshold(tmp_path, monkeypatch):
    metrics_path = tmp_path / "metrics.json"
    _write_metrics(metrics_path, auc=0.85, ap=0.75)
    monkeypatch.setenv("MIN_ROC_AUC", "0.8")
    monkeypatch.setenv("MIN_AVG_PRECISION", "0.7")
    validate_metrics(metrics_path=metrics_path)
