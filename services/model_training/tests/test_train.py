from services.model_training.train import build_pipeline


def test_build_pipeline_has_model():
    pipeline = build_pipeline()
    assert "model" in pipeline.named_steps
    assert pipeline.named_steps["model"].max_iter == 200
