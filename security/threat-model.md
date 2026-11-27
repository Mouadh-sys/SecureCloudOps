# SecureCloudOps Threat Model

## Assets

- Confidential customer documents in Amazon S3
- Document metadata and database records
- Application credentials in AWS Secrets Manager
- CloudTrail, Flow Logs, and security findings
- EC2 and IAM workload identities

## Trust boundaries

- Public internet to the public load-balancer tier
- Public tier to private application tier
- Application tier to database and AWS control/data planes
- AWS monitoring services to EventBridge and Lambda
- Security operator to SNS notifications

## Threats and mitigations

| Threat | Risk | Mitigation | Validation |
|---|---|---|---|
| Public document exposure | Confidentiality loss | S3 Block Public Access, HTTPS-only policy, private bucket, KMS encryption | SC-01, SC-04 |
| Compromised application identity | Unauthorized AWS access | Instance role, resource-scoped IAM policies, no embedded credentials | SC-03 |
| Database access from untrusted network | Confidentiality/integrity loss | Private subnets, public access disabled, application-only Security Group | SC-02 |
| Loss of audit evidence | Reduced detection and investigation capability | CloudTrail, encrypted audit bucket, CloudWatch retention, Flow Logs | SC-06 |
| Malicious or accidental deletion | Data loss | S3 versioning, lifecycle review, backup procedures | SC-10 |
| Unsafe automated response | Availability loss | Notification-only mode; no containment action enabled | SC-08 |
| Excessive log or response costs | Operational disruption | Short CloudWatch retention and conditional expensive services | Cost review |

## Assumptions

- AWS Academy credentials are temporary and managed outside Terraform.
- The baseline does not expose SSH or a public database.
- Automatic containment remains disabled.
- Conditional services are enabled only when permissions and cost limits allow.

## Residual risks

- An egress Security Group permits outbound traffic for laboratory simplicity.
- No production NAT, WAF, load balancer, or TLS certificate is included by default.
- Academy account isolation and permission restrictions may prevent full control deployment.