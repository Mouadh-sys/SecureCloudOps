output "kms_key_arn" {
  value = aws_kms_key.data.arn
}

output "kms_key_id" {
  value = aws_kms_key.data.key_id
}

output "documents_bucket_name" {
  value = local.documents_bucket_name
}

output "documents_bucket_arn" {
  value = local.documents_bucket_arn
}

output "audit_bucket_name" {
  value = local.audit_bucket_name
}

output "audit_bucket_arn" {
  value = local.audit_bucket_arn
}

output "application_secret_arn" {
  value = aws_secretsmanager_secret.application.arn
}
