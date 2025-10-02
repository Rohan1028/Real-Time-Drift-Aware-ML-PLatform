# Architecture & Data Contracts

## System Overview

The platform orchestrates a fraud-style binary classifier with real-time feedback:

1. **Event Producer** publishes synthetic `transactions` to Redpanda.
2. **Feature Store (Feast)** maintains offline Parquet snapshots in MinIO and online feature values in Redis.
3. **Model Training** pipelines run locally with scikit-learn and log to MLflow.
4. **Serving Layer** runs on Ray Serve with FastAPI ingress supporting canary and shadow flows.
5. **Monitoring** collects Prometheus metrics, OpenTelemetry traces, and Evidently drift reports.
6. **Automation** handled via Make targets, CI pipelines, IaC stubs, and Argo CD manifests for GitOps.

![Dataflow](../diagrams/dataflow.png)

## Data Contracts

| Field                | Type        | Description                                     | Constraints                              | PII |
|----------------------|------------|-------------------------------------------------|------------------------------------------|-----|
| `event_id`           | string     | Unique ULID per event                           | Non-null, 26-char ULID                   | No  |
| `user_id`            | string     | Actor identifier (hashed)                       | Non-null, matches `user-[0-9]+`          | Pseudonymized |
| `transaction_amount` | float      | Amount in USD                                   | `>= 0`, `<= 5000`                        | No  |
| `country`            | string     | ISO alpha-2 country code                        | Enum: `US, CA, GB, DE, FR, IN, BR`       | No  |
| `device`             | string     | Device category                                 | Enum: `ios, android, web`                | No  |
| `event_ts`           | timestamp  | Event time in ISO-8601 UTC                      | Non-null, no future timestamps > 1 min   | No  |
| `label`              | int        | Binary fraud label (1 positive)                 | Nullable in live stream (delayed truth)  | No  |

Generated JSON schema available via `services/common/schemas.py`.

## SLAs / SLOs

- **Latency**: p95 inference < 200 ms (monitored via Prometheus).
- **Availability**: 99.5% for inference host (tracked through `/health`).
- **Drift**: PSI threshold ≤ 0.3; triggers Evidently alert pipeline.
- **Freshness**: Online features lag < 2 minutes (validated by Feast materialization timestamp).

## Retraining & Promotion

- Retrain hourly during demo using new Parquet batches.
- Promotion requires:
  - AUC ≥ current staging.
  - Drift score < 0.3 in previous window.
  - Canary error rate ≤ 1%.

## Observability Goals

- Correlate request traces (`trace_id`) with feature fetches and model evaluation.
- Expose Grafana dashboards:
  - `Inference SLO`: latency percentiles, throughput, error rate.
  - `Traffic Split`: canary vs baseline.
  - `Drift Overview`: PSI and feature-wise drift scores.

## Security & Compliance Summary

- MinIO bucket stores synthetic, non-PII sample data.
- Secrets pulled from `.env`, never committed.
- Terraform/Argo CD files marked `for reference only`; no real credentials included.
- Pre-commit secret scanning ensures compliance.
