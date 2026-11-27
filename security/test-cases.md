# SecureCloudOps Test Cases

Record date, AWS account, region, tester, command or console path, observed result, evidence location, and exceptions for every scenario.

| ID | Scenario | Procedure | Expected result | Status |
|---|---|---|---|---|
| SC-01 | Attempt public access to document bucket | Use an unauthenticated request or alternate principal against a known object | Access denied | Not run |
| SC-02 | Unauthorized database network access | Future test only if an RDS instance is separately approved and implemented | Connection denied by network controls | N/A; RDS is not implemented |
| SC-03 | Application access without authorized credentials | The synthetic demo does not access AWS data services; verify it contains no credentials or write operations | No credentials are present; write methods return 405 | Not run |
| SC-04 | Inspect S3 encryption | `aws s3api get-bucket-encryption --bucket "$(terraform output -raw documents_bucket_name)"` | KMS `aws:kms` configuration | Not run |
| SC-05 | Inspect EC2/EBS encryption | Inspect both application instances and the optional security-test instance and attached volumes | No public IP; IMDSv2 required; EBS encryption enabled | N/A until workload is deployed |
| SC-06 | Generate controlled security test event | Publish a synthetic EventBridge-compatible finding or trigger a test rule | Finding reaches EventBridge | Not run |
| SC-07 | Trigger an EventBridge rule | Submit a synthetic event matching the GuardDuty or Security Hub rule | SNS topic receives the event directly | Not run |
| SC-08 | Review simulated finding | Confirm the SNS subscription, inspect the notification, and record a manual disposition | Operator is notified; no resource is modified automatically | Not run |
| SC-09 | Inspect IaC policy | Run `./scripts/validate-iac.sh` with Checkov installed | Local Terraform security findings are reviewed and recorded | Not run |
| SC-10 | Restore protected workload resource | Restore a test backup or validated S3 object version in an isolated test scope | Restored data is accessible and evidence recorded | N/A until backup target exists |
| SC-11 | Verify allowlisted HTTPS ingress | From the configured client CIDR, request the application using the ACM-covered DNS name; retry from a different source if available | HTTPS succeeds only from the allowlisted CIDR; no HTTP listener is exposed | N/A until workload is deployed |
| SC-12 | Verify read-only application behavior | Request `/`, `/health`, `/api/documents`; submit a POST to `/api/documents` | GET routes return expected synthetic content; POST returns 405 | Not run |
| SC-13 | Verify private management access | Start an SSM Session Manager session to `scops-sec-01`; inspect its network interface | Session works; instance has no public IP and accepts no inbound SSH | N/A until workload is deployed |
| SC-14 | Verify target-health alert | In an approved test window, make one target unhealthy without changing security controls permanently | CloudWatch alarm transitions and publishes to the security SNS topic | N/A until workload is deployed |

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