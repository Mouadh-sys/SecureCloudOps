output "aws_account_id" {
  description = "Authenticated AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_caller_arn" {
  description = "Authenticated AWS identity ARN"
  value       = data.aws_caller_identity.current.arn
}

output "aws_region" {
  description = "Selected AWS region"
  value       = data.aws_region.current.region
}

output "vpc_id" {
  description = "SecureCloudOps VPC ID"
  value       = module.networking.vpc_id
}

output "documents_bucket_name" {
  description = "Private encrypted document bucket"
  value       = module.storage.documents_bucket_name
}

output "audit_bucket_name" {
  description = "Protected audit log bucket"
  value       = module.storage.audit_bucket_name
}

output "kms_key_arn" {
  description = "Customer-managed data encryption key"
  value       = module.storage.kms_key_arn
}

output "application_instance_profile_name" {
  description = "IAM instance profile for the application workload"
  value       = module.identity.application_instance_profile_name
}

output "security_topic_arn" {
  description = "SNS topic for security findings"
  value       = module.incident_response.sns_topic_arn
}

output "application_load_balancer_dns_name" {
  description = "Public DNS name of the HTTPS application load balancer"
  value       = module.workload.load_balancer_dns_name
}

output "application_instance_ids" {
  description = "EC2 instance IDs for the private application nodes"
  value       = module.workload.application_instance_ids
}

output "security_test_instance_id" {
  description = "EC2 instance ID for the private defensive validation host, if enabled"
  value       = module.workload.security_test_instance_id
}