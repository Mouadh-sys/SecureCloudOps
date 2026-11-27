# SecureCloudOps Test Cases

Record date, AWS account, region, tester, command or console path, observed result, evidence location, and exceptions for every scenario.

| ID | Scenario | Procedure | Expected result | Status |
|---|---|---|---|---|
| SC-01 | Attempt public access to document bucket | Use an unauthenticated request or alternate principal against a known object | Access denied | Not run |
| SC-02 | Unauthorized database network access | From outside the application Security Group, attempt the database port; do not add real credentials | Connection denied by network controls | Not run |
| SC-03 | Application access without authorized credentials | Access AWS resources without the application instance role or with a non-project identity | Access denied | Not run |
| SC-04 | Inspect S3 encryption | `aws s3api get-bucket-encryption --bucket <bucket>` | KMS `aws:kms` configuration | Not run |
| SC-05 | Inspect EC2/EBS encryption | Inspect an EC2 instance and attached volume when the workload is deployed | EBS encryption enabled | N/A until EC2 is deployed |
| SC-06 | Generate controlled security test event | Publish a synthetic EventBridge-compatible finding or trigger a test rule | Finding reaches EventBridge | Not run |
| SC-07 | Trigger an EventBridge rule | Submit a matching GuardDuty or Security Hub finding event | Lambda function invoked | Not run |
| SC-08 | Process simulated finding | Invoke Lambda with a synthetic finding payload | Finding is classified, logged, and SNS published; no resource is modified | Not run |
| SC-09 | Inspect external access | Review IAM Access Analyzer findings and S3 public controls | No unintended external access or explicitly reviewed findings | Not run |
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