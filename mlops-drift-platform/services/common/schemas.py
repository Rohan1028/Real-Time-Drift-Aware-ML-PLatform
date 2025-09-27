from __future__ import annotations

from datetime import datetime
from typing import Any, Dict

from pydantic import BaseModel, Field, field_validator, model_validator


class Event(BaseModel):
    event_id: str = Field(..., description="ULID identifier")
    user_id: str = Field(..., description="User identifier")
    transaction_amount: float = Field(..., ge=0.0, le=5000.0)
    country: str = Field(..., pattern="^(US|CA|GB|DE|FR|IN|BR)$")
    device: str = Field(..., pattern="^(ios|android|web)$")
    event_ts: datetime = Field(..., description="UTC timestamp")
    label: int | None = Field(default=None, ge=0, le=1)

    @field_validator("event_id")
    @classmethod
    def validate_event_id(cls, value: str) -> str:
        if len(value) < 10:
            raise ValueError("event_id too short")
        return value

    @model_validator(mode="after")
    def check_future_timestamp(self) -> "Event":
        if self.event_ts is not None and self.event_ts > datetime.utcnow().astimezone():
            raise ValueError("event_ts cannot be in the future")
        return self


class FeatureVector(BaseModel):
    user_id: str
    transaction_amount: float
    amount_zscore: float | None = None
    country_onehot: Dict[str, float] | None = None
    device_onehot: Dict[str, float] | None = None
    event_ts: datetime


class InferenceRequest(BaseModel):
    user_id: str
    event: Event


class InferenceResponse(BaseModel):
    user_id: str
    model_version: str
    score: float
    decision: str
    canary_variant: str
    trace_id: str | None = None


def event_json_schema() -> Dict[str, Any]:
    return Event.model_json_schema()
