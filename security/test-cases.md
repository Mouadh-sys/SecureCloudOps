# SecureCloudOps Test Cases

Record date, AWS account, region, tester, command or console path, observed result, evidence location, and exceptions for every scenario.

| ID | Scenario | Procedure | Expected result | Status |
|---|---|---|---|---|
| SC-01 | Attempt public access to document bucket | Use an unauthenticated request or alternate principal against a known object | Access denied | Not run |
| SC-02 | Unauthorized database network access | From outside the application Security Group, attempt the database port; do not add real credentials | Connection denied by network controls | Not run |
| SC-03 | Application access without authorized credentials | When an EC2 workload is deployed, access AWS resources without the Academy instance profile | Access denied | N/A until EC2 is deployed |
| SC-04 | Inspect S3 encryption | `aws s3api get-bucket-encryption --bucket "$(terraform output -raw documents_bucket_name)"` | KMS `aws:kms` configuration | Not run |
| SC-05 | Inspect EC2/EBS encryption | Inspect an EC2 instance and attached volume when the workload is deployed | EBS encryption enabled | N/A until EC2 is deployed |
| SC-06 | Generate controlled security test event | Publish a synthetic EventBridge-compatible finding or trigger a test rule | Finding reaches EventBridge | Not run |
| SC-07 | Trigger an EventBridge rule | Submit a synthetic event matching the GuardDuty or Security Hub rule | SNS topic receives the event directly | Not run |
| SC-08 | Review simulated finding | Confirm the SNS subscription, inspect the notification, and record a manual disposition | Operator is notified; no resource is modified automatically | Not run |
| SC-09 | Inspect IaC policy | Run `./scripts/validate-iac.sh` with Checkov installed | Local Terraform security findings are reviewed and recorded | Not run |
| SC-10 | Restore protected workload resource | Restore a test backup or validated S3 object version in an isolated test scope | Restored data is accessible and evidence recorded | N/A until backup target exists |

## Evidence template

```text
Test ID:
Date:
Account:
Region:
Tester:
Command or console action:
Observed result:
Evidence:
Limitation or follow-up:
```