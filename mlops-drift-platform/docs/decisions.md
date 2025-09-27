# Architectural Decisions

## ADR-001: Redpanda vs. Local Kafka
- **Decision**: Adopt Redpanda for local message bus.
- **Status**: Accepted.
- **Context**: Kafka is heavyweight for laptops; Redpanda is drop-in compatible.
- **Consequences**: Future cloud deployment would switch to MSK/PubSub via Terraform variables.

## ADR-002: Ray Serve for Model Inference
- **Decision**: Use Ray Serve to orchestrate multiphase deployments (baseline + canary + shadow).
- **Status**: Accepted.
- **Context**: Ray gives native scaling and flexible traffic splitting.
- **Consequences**: Adds dependency on Ray runtime; containerized for local demo.

## ADR-003: Feast with Postgres + Redis
- **Decision**: Postgres offline store, Redis online store.
- **Status**: Accepted.
- **Context**: Aligns with popular MLOps stacks; keeps demo reproducible.
- **Consequences**: Ensure Postgres migrations run before Feast apply; Redis persistence optional.

## ADR-004: MLflow Registry
- **Decision**: Promote models via MLflow Model Registry.
- **Status**: Accepted.
- **Context**: Simple and well understood for recruiters.
- **Consequences**: Registry served from same container; future stateful storage handled via Terraform stubs.

## ADR-005: Evidently for Drift Detection
- **Decision**: Use Evidently `DataDriftPreset`.
- **Status**: Accepted.
- **Context**: Quick HTML/JSON artifacts, integrable with CI and dashboards.
- **Consequences**: Batch job scheduled nightly; monitoring service bundles script.

## ADR-006: GitOps with Argo CD
- **Decision**: Provide Kustomize bases & Argo Applications.
- **Status**: Proposed (reference only).
- **Context**: Recruiters expect to see GitOps ready manifests even if demo is Docker Compose.
- **Consequences**: Must document non-functional nature; secrets/credentials omitted.
