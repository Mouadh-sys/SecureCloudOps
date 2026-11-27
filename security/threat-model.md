# SecureCloudOps Threat Model

## Assets

- Confidential customer documents in Amazon S3
- Document metadata and database records
- Application credentials in AWS Secrets Manager
- CloudTrail, Flow Logs, and security findings
- Existing Academy-provided EC2 instance profile, when a workload is deployed

## Trust boundaries

- Public internet to the public load-balancer tier
- Public tier to private application tier
- Application tier to database and AWS control/data planes
- AWS finding sources to EventBridge and SNS
- Security operator to SNS notifications

## Threats and mitigations

| Threat | Risk | Mitigation | Validation |
|---|---|---|---|
| Public document exposure | Confidentiality loss | S3 Block Public Access, HTTPS-only policy, private bucket, KMS encryption | SC-01, SC-04 |
| Compromised application identity | Unauthorized AWS access | No workload by default; reuse of broad LabRole is conditional and must be reviewed | SC-03 |
| Database access from untrusted network | Confidentiality/integrity loss | Private subnets, public access disabled, application-only Security Group | SC-02 |
| Loss of audit evidence | Reduced detection and investigation capability | CloudTrail, existing audit bucket, direct-to-S3 Flow Logs, local evidence retention | SC-06 |
| Malicious or accidental deletion | Data loss | S3 versioning, lifecycle review, backup procedures | SC-10 |
| Unsafe automated response | Availability loss | EventBridge-to-SNS only; manual response and no automatic containment | SC-08 |
| Excessive log or response costs | Operational disruption | Short CloudWatch retention and conditional expensive services | Cost review |

## Assumptions

- AWS Academy credentials are temporary and managed outside Terraform.
- The baseline deploys no EC2 workload or public database.
- Existing S3 bucket bases are not Terraform-managed due an explicit organization SCP denial.
- Custom IAM roles and Lambda are excluded.
- Conditional services are enabled only when permissions and cost limits allow.

## Residual risks

- An egress Security Group permits outbound traffic for laboratory simplicity.
- No production NAT, WAF, load balancer, TLS certificate, automated response, or Access Analyzer is included.
- Academy account isolation and permission restrictions may prevent full control deployment.