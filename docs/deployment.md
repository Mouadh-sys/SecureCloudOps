# SecureCloudOps Deployment Guide

## Scope

This guide deploys the laboratory baseline in `us-east-1`. Services that require unavailable Academy permissions or add avoidable cost remain conditional.

## Preflight

1. Confirm AWS credentials:

   ```bash
   aws sts get-caller-identity
   aws configure get region
   ```

2. Confirm the target account and region are correct.
3. Review available quotas and costs.
4. Run capability checks:

   ```bash
   ./scripts/check-capabilities.sh
   ```

## Terraform deployment

```bash
cd terraform/environments/dev
terraform init
terraform fmt -check
terraform validate
terraform plan -out=securecloudops.tfplan
```

### Preserve the partial deployment before planning

The previous apply created resources, including two S3 buckets, but failed because the organization SCP denies `s3:GetBucketObjectLockConfiguration`. Terraform's S3 bucket resource calls this API during refresh. Preserve the buckets and remove only their base resource entries from Terraform state; this does not delete AWS resources.

1. Back up the local state securely and do not commit the backup:

   ```bash
   cp -p terraform.tfstate "$HOME/securecloudops-terraform.tfstate.backup"
   chmod 600 "$HOME/securecloudops-terraform.tfstate.backup"
   ```

2. From `terraform/environments/dev`, stop tracking only the two base bucket resources and the generated archive data source:

   ```bash
   terraform state rm \
     'module.storage.aws_s3_bucket.documents' \
     'module.storage.aws_s3_bucket.audit' \
     'module.incident_response.data.archive_file.lambda'
   ```

3. Confirm the S3 bucket names still match the existing `securecloudops-documents-<account>-dev` and `securecloudops-audit-<account>-dev` buckets. The Terraform configuration uses the authenticated account ID and environment to derive these names.
4. Run `terraform plan -out=securecloudops.tfplan` and inspect the full plan. It must not propose destroying existing VPC/networking, KMS, Secrets Manager, log groups, EventBridge rules, SNS topic, or S3 buckets. The base buckets are external resources; supported bucket settings and policies remain managed separately.
5. Do not apply if the plan shows unintended changes or the S3 provider still requests the denied Object Lock API.

Do not run `terraform apply` until the plan has been reviewed and the operator has decided to proceed.

The baseline creates:

- The SecureCloudOps VPC and six-tier subnets
- Public and private route tables
- ALB, application, and database Security Groups
- S3 Gateway Endpoint
- KMS key and security configuration for the existing document/audit buckets
- A read-only reference to the Academy-provided `LabInstanceProfile`
- CloudWatch log groups, direct-to-S3 VPC Flow Logs, and CloudTrail
- SNS topic policy and EventBridge-to-SNS rules

No custom IAM role, EC2 instance, RDS instance, load balancer, NAT Gateway, Lambda, IAM Access Analyzer, or GuardDuty detector is deployed by the baseline. GuardDuty and Security Hub findings are routed only if those services are separately enabled and permitted.

Run local policy checks with Checkov installed:

```bash
./scripts/validate-iac.sh
```

## Post-deployment validation

Run:

```bash
aws ec2 describe-vpcs --filters Name=tag:Project,Values=SecureCloudOps
aws s3api get-public-access-block --bucket "$(terraform output -raw documents_bucket_name)"
aws s3api get-bucket-encryption --bucket "$(terraform output -raw documents_bucket_name)"
aws cloudtrail describe-trails --query 'trailList[?Name==`securecloudops-dev`]'
aws sns list-subscriptions-by-topic --topic-arn "$(terraform output -raw security_topic_arn)"
```

Record the commands and outputs in [test-cases.md](../security/test-cases.md).

## Manual notification setup

Terraform creates the SNS topic but does not choose or subscribe an operator email address. After deployment, subscribe the intended recipient:

```bash
aws sns subscribe \
  --topic-arn "$(terraform output -raw security_topic_arn)" \
  --protocol email \
  --notification-endpoint <operator-email>
```

Open the confirmation email and follow its confirmation link. Until the subscription is confirmed, the topic has no confirmed email recipient.

GuardDuty and Security Hub are not enabled by this baseline. Enable either service in the AWS console only if it is permitted by the Academy account and acceptable for the lab's cost limits. Findings from those services will not flow through the configured rules unless the corresponding service is enabled.

## Incident response test

Subscribe and confirm the security operator's email, then send a synthetic matching EventBridge event. The event is delivered directly to SNS; the operator reviews and records the response manually.

## Cleanup

```bash
cd terraform/environments/dev
terraform destroy
```

Review the destroy plan. The externally managed bucket bases are not removed by Terraform. Review bucket contents, versions, secrets, and retained CloudWatch logs separately. Terraform cannot bypass retention or organization-level denies.