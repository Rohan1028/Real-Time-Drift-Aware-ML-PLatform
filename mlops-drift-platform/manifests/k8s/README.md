# Kubernetes Manifests (Reference)

These manifests illustrate how the local stack could be deployed via GitOps. They are **not** production ready and omit secrets.

Usage example:

```bash
kustomize build overlays/local | kubectl apply -f -
```

Ensure supporting infrastructure (Kafka, MinIO, MLflow) exists before applying.
