# SecureCloudOps

SecureCloudOps is an AWS Academy security engineering project that demonstrates network isolation, least-privilege IAM, encryption, centralized audit logging, security findings, and notification-only incident response using Terraform.

## Architecture

- VPC `10.20.0.0/16` with public, application, and database subnets across two availability zones
- S3 Gateway Endpoint and no NAT Gateway
- Private document bucket with KMS encryption, versioning, and public-access blocking
- KMS customer-managed key and KMS-backed Secrets Manager secret
- Application EC2 instance role scoped to document, KMS, and secret resources
- CloudTrail, VPC Flow Logs, CloudWatch Logs, and IAM Access Analyzer
- EventBridge, Lambda, SNS, and CloudWatch evidence recording

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
terraform plan
terraform apply
```

AWS Academy credentials must never be committed. Use environment variables or the AWS CLI credential process.

## Validate

```bash
./security/check-capabilites.sh
```

Complete the scenarios in [test-cases.md](security/test-cases.md). Record the observed values and any Academy permission limitations.

## Destroy

```bash
cd terraform/environments/dev
terraform destroy
```

Destroy only resources in this project account and region. Review S3 buckets and secrets before deletion, and do not use Object Lock unless it is part of an explicitly approved exercise.