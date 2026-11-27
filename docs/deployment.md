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
   ./security/check-capabilites.sh
   ```

## Terraform deployment

```bash
cd terraform/environments/dev
terraform init
terraform fmt -check
terraform validate
terraform plan -out=securecloudops.tfplan
terraform apply securecloudops.tfplan
terraform output
```

The baseline creates:

- The SecureCloudOps VPC and six-tier subnets
- Public and private route tables
- ALB, application, and database Security Groups
- S3 Gateway Endpoint
- KMS key and private document/audit buckets
- Application IAM role and instance profile
- CloudWatch log groups, VPC Flow Logs, CloudTrail, and Access Analyzer
- SNS topic, Lambda processor, and EventBridge rules

No EC2 instance, RDS instance, load balancer, NAT Gateway, or GuardDuty detector is enabled by the baseline. This prevents unnecessary cost and avoids claiming controls that have not been deployed.

## Post-deployment validation

Run:

```bash
aws ec2 describe-vpcs --filters Name=tag:Project,Values=SecureCloudOps
aws s3api get-public-access-block --bucket <documents-bucket>
aws s3api get-bucket-encryption --bucket <documents-bucket>
aws cloudtrail get-trail-status --name <cloudtrail-name>
aws sns list-subscriptions-by-topic --topic-arn <security-topic-arn>
```

Record the commands and outputs in [test-cases.md](../security/test-cases.md).

## Incident response test

Send a synthetic EventBridge event with the AWS CLI or put a test event through the console. The function records the finding and publishes an SNS notification only; it does not change resources or isolate workloads.

## Cleanup

```bash
cd terraform/environments/dev
terraform destroy
```

Review any bucket contents, S3 object versions, secrets, and retained CloudWatch logs before destroying. Terraform cannot bypass retention that is enforced externally.