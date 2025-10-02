from services.common.schemas import InferenceRequest, InferenceResponse


def test_inference_request_schema():
    payload = {
        "user_id": "user-1",
        "event": {
            "event_id": "01HQA7F9G4G1YJ2R4D8K2J3A5S",
            "user_id": "user-1",
            "transaction_amount": 12.3,
            "country": "US",
            "device": "ios",
            "event_ts": "2024-02-01T00:00:00Z",
            "label": 0,
        },
    }
    req = InferenceRequest(**payload)
    assert req.user_id == "user-1"


def test_inference_response_schema():
    resp = InferenceResponse(
        user_id="user-1",
        model_version="staging",
        score=0.42,
        decision="approve",
        canary_variant="baseline",
    )
    assert resp.score == 0.42
