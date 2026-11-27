# AWS Capability Matrix

| Capability | Terraform baseline | Academy-dependent | Deployment status |
|---|---|---|---|
| VPC, subnets, route tables | Yes | Quotas | Implemented by module |
| Security Groups | Yes | Quotas | Implemented by module |
| Existing S3 private/encrypted bucket bases | No | SCP denies `s3:GetBucketObjectLockConfiguration` | Preserved outside Terraform state |
| S3 bucket security subresources and policies | Yes | Per-action permissions | Managed separately from bucket bases |
| KMS CMK | Yes | Key creation/key policy permissions | Implemented by module |
| Secrets Manager | Yes | Service availability | Implemented by module |
| IAM workload identity | No new roles | Existing LabRole trust and `iam:PassRole` | `LabInstanceProfile` exists; reuse is conditional |
| CloudTrail | Yes | CloudTrail permissions and existing trail policy | Implemented by module |
| VPC Flow Logs | Yes | `ec2:CreateFlowLogs` and S3 delivery bucket policy | Direct to existing S3 audit bucket; no delivery role |
| IAM Access Analyzer | No | Tagging explicitly denied | Replaced by local IaC checks |
| EventBridge | Yes | Rule and target permissions | Routes findings directly to SNS |
| Lambda | No | Custom execution role cannot be created | Excluded |
| SNS | Yes | Topic policy permissions | Manual operator subscription required |
| GuardDuty | No | Enablement and detector permissions | Conditional; rules are ready if enabled |
| Security Hub | No | Enablement and finding aggregation | Conditional; rules are ready if enabled |
| Macie | No | Account enablement and cost | Conditional |
| EC2 application workload | No | AMI, quota, and permissions | Conditional |
| RDS | No | Engine availability and cost | Conditional |
| AWS Backup | No | Service and vault permissions | Conditional |