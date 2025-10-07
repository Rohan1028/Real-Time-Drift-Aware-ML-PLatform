import pytest

from services.serving.app.model_loader import ModelLoadError, load_model


def test_load_model_failure(monkeypatch):
    def _raise(**_kwargs):
        raise RuntimeError("mlflow down")

    monkeypatch.setattr("services.serving.app.model_loader.mlflow.pyfunc.load_model", _raise)
    try:
        with pytest.raises(ModelLoadError):
            load_model("models:/fraud-detector/Staging")
    finally:
        load_model.cache_clear()
