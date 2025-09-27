from datetime import timedelta

from feast import FileSource


events_source = FileSource(
    path="data/sample/events.parquet",
    timestamp_field="event_ts",
    created_timestamp_column="created_at",
)

live_source = FileSource(
    path="data/sample/events.parquet",
    timestamp_field="event_ts",
    created_timestamp_column="created_at",
    max_age=timedelta(hours=1),
)
