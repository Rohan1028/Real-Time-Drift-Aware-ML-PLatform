import pytest

from services.monitoring.drift.run_evidently import generate_report, load_data


def test_generate_report(tmp_path, monkeypatch):
    json_path = generate_report(report_dir=tmp_path)
    assert (tmp_path / "latest.html").exists()
    assert json_path.exists()


def test_load_data_missing_override(tmp_path, monkeypatch):
    monkeypatch.setenv("DRIFT_REFERENCE_PATH", str(tmp_path / "missing_ref.csv"))
    monkeypatch.setenv("DRIFT_CURRENT_PATH", str(tmp_path / "missing_cur.csv"))
    with pytest.raises(RuntimeError):
        load_data()
