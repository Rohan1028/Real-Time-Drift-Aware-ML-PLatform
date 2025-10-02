from pathlib import Path

from services.monitoring.drift.run_evidently import REPORT_DIR, generate_report


def test_generate_report(tmp_path, monkeypatch):
    monkeypatch.setattr("services.monitoring.drift.run_evidently.REPORT_DIR", tmp_path)
    generate_report()
    assert (tmp_path / "latest.html").exists()
    assert (tmp_path / "latest.json").exists()
