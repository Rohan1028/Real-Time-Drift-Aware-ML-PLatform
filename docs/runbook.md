# Runbook: Real-Time Drift-Aware ML Platform

## 1. Incident Intake

- Channels: Slack `#mlops-alerts`, PagerDuty "Drift Platform" service.
- Severity levels:
  - SEV1 – Inference outage (>10 mins).
  - SEV2 – Drift alert or sustained SLO breach.
  - SEV3 – Non-blocking issues (delayed feature materialization).

## 2. Immediate Checks

1. Confirm alert details in Prometheus Alertmanager (`http://localhost:9093` when running stack).
2. Validate service health:
   - `curl http://localhost:8000/health`
   - `docker compose logs serving`
   - Grafana dashboard "Inference SLO" panel status.

## 3. Diagnostic Workflow

- **Latency spike**: Check Ray Serve metrics (`ray status`, `serving_app_request_latency_seconds_bucket`).
- **Drift alert**: Inspect latest HTML report in `services/monitoring/drift/reports/`.
- **Feature lag**: Review Feast materialization job logs, confirm Redis keys.

## 4. Rollback Procedure

1. Ensure stack running (`make compose-up`).
2. Run `poetry run python services/serving/app/rollback.py --confirm`.
3. Validate Prometheus metrics reflect `model_variant="baseline"` dominance.
4. Notify stakeholders, log timeline in incident doc.

## 5. Shadow Model Review

- Query MLflow run tagged `shadow=true`.
- Validate accuracy metrics and latency.
- If acceptable, update `CANARY_SPLIT` in deployment env and redeploy via `make serve`.

## 6. Regression Checks

- `make test-unit` for fast signal on canary/shadow paths.
- `make test-integration` to replay synthetic events through the inference surface.
- After `make train`, run `make test-regression` to generate Evidently reports with fixture data and enforce metric thresholds (`services/model_training/validate_metrics.py`).
- Drift fixtures live under `data/sample/drift_reference.csv` and `data/sample/drift_current.csv`; override via `DRIFT_REFERENCE_PATH` / `DRIFT_CURRENT_PATH`.

## 7. Post-Incident

- Record timeline in `docs/incidents/YYYY-MM-DD.md` (create as needed).
- File Jira ticket for follow-up automation.
- Add retro notes to `docs/decisions.md` if architecture changes.

## 8. Contacts

| Role        | Primary             | Backup           |
|-------------|---------------------|------------------|
| ML Platform | engineering@demo.io | sre@demo.io      |
| Data Science| ds-lead@demo.io     | analyst@demo.io  |
