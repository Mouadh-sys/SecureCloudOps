# AWS Capability Matrix

| Capability | Terraform baseline | Academy-dependent | Deployment status |
|---|---|---|---|
| VPC, subnets, route tables | Yes | Quotas | Implemented by module |
| Security Groups | Yes | Quotas | Implemented by module |
| S3 private/encrypted bucket | Yes | Naming and bucket policy permissions | Implemented by module |
| KMS CMK | Yes | Key creation/key policy permissions | Implemented by module |
| Secrets Manager | Yes | Service availability | Implemented by module |
| IAM workload role | Yes | Role and instance-profile permissions | Implemented by module |
| CloudTrail | Yes | CloudTrail permissions and existing trail policy | Implemented by module |
| VPC Flow Logs | Yes | CloudWatch Logs permissions | Implemented by module |
| IAM Access Analyzer | Yes | Service-linked setup permission | Implemented by module |
| EventBridge | Yes | Rule permissions | Implemented by module |
| Lambda | Yes | Runtime and IAM role permissions | Implemented by module |
| SNS | Yes | Topic permissions | Implemented by module |
| GuardDuty | No | Enablement and detector permissions | Conditional |
| Security Hub | No | Enablement and finding aggregation | Conditional |
| Macie | No | Account enablement and cost | Conditional |
| EC2 application workload | No | AMI, quota, and permissions | Conditional |
| RDS | No | Engine availability and cost | Conditional |
| AWS Backup | No | Service and vault permissions | Conditional |