# SecureCloudOps

SecureCloudOps is an AWS Academy security engineering project that demonstrates network isolation, encryption, centralized audit logging, security findings, and notification-only incident response using Terraform adapted to Learner Lab permissions.

## Architecture

- VPC `10.20.0.0/16` with public, application, and database subnets across two availability zones
- S3 Gateway Endpoint and no NAT Gateway
- Existing document and audit buckets with Terraform-managed security subresources; the bucket bases remain outside Terraform state because an organization SCP denies the provider's Object Lock read
- KMS customer-managed key and KMS-backed Secrets Manager secret
- Existing `LabRole` / `LabInstanceProfile` referenced for an optional EC2 workload; no IAM roles are created
- CloudTrail, VPC Flow Logs delivered directly to S3, and CloudWatch Logs
- EventBridge-to-SNS findings notification with manual operator response
- Local IaC policy scanning in place of IAM Access Analyzer

See [architecture.md](docs/architecture.md) for the target design and [deployment.md](docs/deployment.md) for operations.

## Prerequisites

- Terraform 1.6 or newer
- AWS CLI
- Temporary AWS Academy credentials
- Permissions for the resources in the selected environment

## Deploy

```bash
cd terraform/environments/dev
terraform init
terraform fmt -check
terraform validate
terraform plan -out=securecloudops.tfplan
```

Before planning the partially deployed stack, follow the state-preservation steps in [deployment.md](docs/deployment.md). Do not apply until the plan shows no unintended destroys. AWS Academy credentials must never be committed; use the AWS CLI credential process.

## Validate

```bash
./scripts/check-capabilities.sh
```

Run the local IaC checks with `./scripts/validate-iac.sh`. Complete the scenarios in [test-cases.md](security/test-cases.md) and record permission limitations.

## Destroy

```bash
cd terraform/environments/dev
terraform destroy
```

Destroy only after reviewing the plan and preserving any required state. The existing document and audit buckets are intentionally unmanaged by Terraform and will not be removed by this command.