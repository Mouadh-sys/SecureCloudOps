# SecureCloudOps Deployment Guide

## Scope

This guide covers the Learner Lab baseline and the new synthetic document-inventory workload in `us-east-1`. The workload configuration has not been applied. Do not apply it until the operator completes the manual prerequisites below and reviews the current cost estimate.

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

## Required manual prerequisites for the workload

The ALB listener requires an issued ACM certificate, and its Security Group requires a client IPv4 CIDR. Terraform deliberately has no defaults for either value.

1. Choose a DNS name in a domain you control.
2. In AWS Certificate Manager in `us-east-1`, request a public certificate for that name.
3. Complete ACM DNS validation by adding its CNAME record with your DNS provider; wait until the certificate status is **Issued**. Record its ARN.
4. Determine your current public outbound IPv4 address and use it as a `/32` client CIDR, for example `198.51.100.27/32`. Use your real address, not the documentation example; confirm it will remain stable while testing.
5. In `terraform/environments/dev`, create the ignored local `terraform.tfvars` file with:

   ```hcl
   allowed_client_cidr = "<your-public-ipv4>/32"
   acm_certificate_arn = "arn:aws:acm:us-east-1:<account-id>:certificate/<certificate-id>"
   ```

   Do not commit the file. The `.gitignore` already excludes `*.tfvars`.
6. Review current regional pricing for the internet-facing ALB, three `t3.micro` EC2 instances (two app nodes plus the optional test host), EBS volumes, four interface endpoint services in two AZs, CloudWatch Logs, and data processing. These resources incur charges even when the demo has little traffic. Set `enable_security_test_instance = false` in `terraform.tfvars` only if you choose to defer that host.
7. RDS is not included in this workload. It remains deferred until its cost is acceptable and the application is redesigned to use a database; no database resource will be created by the current configuration.

After the ALB is created, point the chosen DNS name at its DNS name using your DNS provider if you want to use the certificate-backed hostname.

## Terraform deployment

```bash
cd terraform/environments/dev
terraform init
terraform fmt -check
terraform validate
terraform plan -out=securecloudops.tfplan
```

### Switching to a different AWS account

Do not refresh an existing account's state with credentials for a different account. Confirm the active identity with `aws sts get-caller-identity`, then create and select an account-specific local workspace to keep its state separate; replace `ACCOUNT_ID` below with the 12-digit AWS account ID:

```bash
terraform workspace list
terraform workspace new learner-lab-ACCOUNT_ID
terraform workspace show
terraform plan -out=securecloudops-new-account.tfplan
```

Keep the original workspace and its state intact. Review the new-account plan carefully before applying; a fresh workspace will propose creating the infrastructure again.

The storage module manages settings for existing S3 buckets but does not create the bucket bases. In a new account, manually create `securecloudops-documents-<account-id>-dev` and `securecloudops-audit-<account-id>-dev` in `us-east-1`, with S3 Block Public Access enabled and Object Lock disabled. Terraform will configure versioning, encryption, and the remaining bucket controls after the buckets exist.

### Preserve the partial deployment before planning

The previous apply created resources, including two S3 buckets, but failed because the organization SCP denies `s3:GetBucketObjectLockConfiguration`. Terraform's S3 bucket resource calls this API during refresh. Preserve the buckets and remove only their base resource entries from Terraform state; this does not delete AWS resources.

1. Back up the local state securely and do not commit the backup:

   ```bash
   test ! -e "$HOME/securecloudops-terraform.tfstate.backup"
   cp -p terraform.tfstate "$HOME/securecloudops-terraform.tfstate.backup"
   chmod 600 "$HOME/securecloudops-terraform.tfstate.backup"
   ```

   If the destination already exists, choose another private filename instead of overwriting it.

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

The Terraform configuration manages:

- The SecureCloudOps VPC and six-tier subnets
- Public and private route tables
- ALB, application, database, endpoint, and defensive-test Security Groups
- S3 Gateway Endpoint and private SSM / CloudWatch Logs interface endpoints
- KMS key and security configuration for the existing document/audit buckets
- A read-only reference to the Academy-provided `LabInstanceProfile`
- Two private application EC2 nodes, an HTTPS ALB, and an optional private SSM-managed validation host
- Synthetic read-only document-inventory application and an unhealthy-target alarm
- CloudWatch log groups, direct-to-S3 VPC Flow Logs, and CloudTrail
- SNS topic policy and EventBridge-to-SNS rules

No custom IAM role, RDS instance, NAT Gateway, Lambda, IAM Access Analyzer, or GuardDuty detector is created by the current configuration. The workload and baseline have not been applied in this step. GuardDuty and Security Hub findings are routed only if those services are separately enabled and permitted.

Install the pinned local policy scanner in a virtual environment:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
```

Then run local policy checks; the script automatically prefers the repository-local Checkov installation:

```bash
./scripts/validate-iac.sh
```

Checkov exceptions are attached to individual Terraform resources with reasons. Review them alongside any failed checks; do not treat skipped checks as passed.

## Post-deployment validation

Run:

```bash
aws ec2 describe-vpcs --filters Name=tag:Project,Values=SecureCloudOps
aws s3api get-public-access-block --bucket "$(terraform output -raw documents_bucket_name)"
aws s3api get-bucket-encryption --bucket "$(terraform output -raw documents_bucket_name)"
aws cloudtrail describe-trails --query 'trailList[?Name==`securecloudops-dev`]'
aws sns list-subscriptions-by-topic --topic-arn "$(terraform output -raw security_topic_arn)"
aws elbv2 describe-load-balancers --names "securecloudops-dev"
aws ec2 describe-instances --filters Name=tag:Name,Values=scops-app-01,scops-app-02,scops-sec-01
```

Record the commands and outputs in [test-cases.md](../security/test-cases.md).

Use Systems Manager Session Manager for the private validation host; it has no public IP or SSH key:

```bash
aws ssm start-session \
  --target "$(terraform output -raw security_test_instance_id)" \
  --region us-east-1
```

The synthetic app exposes `/`, `/health`, and `/api/documents` over HTTPS through the ALB. It has no login or write workflow and must remain restricted to the supplied client CIDR.

## Manual notification setup

Terraform creates the SNS topic but does not choose or subscribe an operator email address. After deployment, subscribe the intended recipient:

```bash
read -r -p "Operator email address: " OPERATOR_EMAIL
aws sns subscribe \
  --topic-arn "$(terraform output -raw security_topic_arn)" \
  --protocol email \
  --notification-endpoint "$OPERATOR_EMAIL"
```

Open the confirmation email and follow its confirmation link. Until the subscription is confirmed, the topic has no confirmed email recipient. Do not store the email address in Terraform variables or source control.

GuardDuty and Security Hub are not enabled by this baseline. Enable either service in the AWS console only if it is permitted by the Academy account and acceptable for the lab's cost limits. Findings from those services will not flow through the configured rules unless the corresponding service is enabled.

## Incident response test

After the SNS subscription is confirmed, send a synthetic matching EventBridge event. The event is delivered directly to SNS; the operator reviews and records the response manually.

## Cleanup

The ALB has deletion protection enabled. Before cleanup, set `enable_deletion_protection = false` in `terraform/modules/workload/main.tf` and apply that change.

```bash
cd terraform/environments/dev
terraform destroy
```

Review the destroy plan. The externally managed bucket bases are not removed by Terraform. Review bucket contents, versions, secrets, and retained CloudWatch logs separately. Terraform cannot bypass retention or organization-level denies.

Do not delete the KMS key while any S3 object or version depends on it. Re-encrypt or remove the data first, or retain the key.