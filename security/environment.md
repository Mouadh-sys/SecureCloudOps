# SecureCloudOps - Environment

| Property | Value |
|---|---|
| Provider | AWS |
| Environment | AWS Academy Learner Lab |
| Region | us-east-1 |
| Identity | assumed-role/voclabs |
| IaC | Terraform |
| Initial validation | Terraform configuration validated; apply partially failed |
| Infrastructure deployed | Partial: VPC/networking, KMS, Secrets Manager, existing S3 buckets, CloudWatch log groups, EventBridge rules, and SNS topic |

## Constraints

- Academy credentials are temporary.
- Permissions are controlled by the Academy role.
- `iam:CreateRole` is denied; use the pre-provisioned `LabRole`/`LabInstanceProfile` only after verifying service trust and `iam:PassRole`.
- An organization SCP explicitly denies `s3:GetBucketObjectLockConfiguration`; Terraform must not manage the base S3 bucket resources.
- IAM Access Analyzer tagging is denied; use local IaC policy checks instead.
- Resource availability and quotas may be restricted.
- Check costs before deploying services.