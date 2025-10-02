import pytest

from services.common.schemas import Event, event_json_schema


def test_event_validates_timestamp():
    event = Event(
        event_id="01HQA7F9G4G1YJ2R4D8K2J3A5S",
        user_id="user-001",
        transaction_amount=10.0,
        country="US",
        device="ios",
        event_ts="2024-02-01T10:00:00Z",
    )
    assert event.user_id == "user-001"


def test_event_schema_contains_fields():
    schema = event_json_schema()
    assert "properties" in schema
    assert "transaction_amount" in schema["properties"]


def test_invalid_country():
    with pytest.raises(ValueError):
        Event(
            event_id="short",
            user_id="user-1",
            transaction_amount=1.0,
            country="XX",
            device="ios",
            event_ts="2024-02-01T10:00:00Z",
        )
