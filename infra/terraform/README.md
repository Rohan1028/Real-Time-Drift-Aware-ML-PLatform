# Terraform Stubs (Reference Only)

> ⚠️ These modules are illustrative and **not** intended for direct apply without review.

## Overview

- `main.tf` provisions AWS or GCP equivalents of local stack components.
- Variables capture networking, IAM, and storage requirements.
- Outputs expose connection strings consumed by GitOps manifests.

## Usage

```bash
cd infra/terraform
cp env/aws.auto.tfvars.example env/aws.auto.tfvars
terraform init
terraform plan -var-file=env/aws.auto.tfvars
```

Do **not** commit filled `*.auto.tfvars` files.
