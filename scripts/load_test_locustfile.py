from locust import HttpUser, between, task

sample_payload = {
    "user_id": "user-123",
    "event": {
        "event_id": "01HQA7F9G4G1YJ2R4D8K2J3A5S",
        "user_id": "user-123",
        "transaction_amount": 120.4,
        "country": "US",
        "device": "ios",
        "event_ts": "2024-02-25T12:03:11Z",
        "label": 0,
    },
}


class InferenceUser(HttpUser):
    wait_time = between(0.1, 0.3)

    @task
    def predict(self):
        self.client.post("/predict", json=sample_payload)
