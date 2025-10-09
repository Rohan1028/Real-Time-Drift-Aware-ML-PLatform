from feast import FeatureView, Field
from feast.types import Float32, Int64

from .data_sources import events_source
from .entities import user

transaction_features = FeatureView(
    name="transaction_features",
    entities=[user],
    ttl=None,
    schema=[
        Field(name="transaction_amount", dtype=Float32),
        Field(name="label", dtype=Int64),
    ],
    online=True,
    source=events_source,
)
