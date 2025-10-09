from prometheus_client import Counter, Histogram

REQUEST_LATENCY = Histogram(
    "serving_app_request_latency_seconds",
    "Request latency",
    buckets=(0.05, 0.1, 0.2, 0.5, 1.0),
    labelnames=("model_variant",),
)

REQUEST_COUNTER = Counter(
    "serving_app_requests_total",
    "Total prediction requests",
    labelnames=("model_variant",),
)

EXCEPTION_COUNTER = Counter(
    "serving_app_request_exceptions_total",
    "Prediction exceptions",
    labelnames=("model_variant",),
)
