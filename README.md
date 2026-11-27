# SecureCloudOps

SecureCloudOps is an AWS Academy security engineering project that demonstrates network isolation, encryption, centralized audit logging, security findings, and notification-only incident response using Terraform adapted to Learner Lab permissions.

## Architecture

- VPC `10.20.0.0/16` with public, application, and database subnets across two availability zones
- S3 Gateway Endpoint and no NAT Gateway
- Existing document and audit buckets with Terraform-managed security subresources; the bucket bases remain outside Terraform state because an organization SCP denies the provider's Object Lock read
- KMS customer-managed key and KMS-backed Secrets Manager secret
- Existing `LabRole` / `LabInstanceProfile` referenced for two private EC2 app nodes and an optional SSM-only test host; no IAM roles are created
- HTTPS ALB restricted to a manually provided client CIDR, synthetic read-only inventory app, CloudWatch application logs and target-health alarm
- CloudTrail, VPC Flow Logs delivered directly to S3, and CloudWatch Logs
- EventBridge-to-SNS findings notification with manual operator response
- Local IaC policy scanning in place of IAM Access Analyzer

See [architecture.md](docs/architecture.md) for the target design and [deployment.md](docs/deployment.md) for operations.

## Prerequisites

- Terraform 1.6 or newer
- AWS CLI
- Checkov for local IaC policy checks
- Temporary AWS Academy credentials
- Permissions for the resources in the selected environment

## Current deployment status

The previous Terraform apply partially succeeded. Existing networking, KMS, Secrets Manager, S3 buckets, CloudWatch log groups, EventBridge rules, and SNS topic are preserved. The revised baseline and workload configuration have not been applied. The document bucket currently uses SSE-S3; planned SSE-KMS settings are not active until a successful apply. Workload deployment is blocked on an issued ACM certificate ARN, the operator's client CIDR, and cost review. RDS is not included.

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

Destroy only after reviewing the plan and preserving any required state. The existing document and audit buckets are intentionally unmanaged by Terraform and will not be removed by this command. Do not delete the KMS key while any S3 objects or versions depend on it.