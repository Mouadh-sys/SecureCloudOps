output "kms_key_arn" {
  value = aws_kms_key.data.arn
}

output "kms_key_id" {
  value = aws_kms_key.data.key_id
}

output "documents_bucket_name" {
  value = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  value = aws_s3_bucket.documents.arn
}

output "audit_bucket_name" {
  value = aws_s3_bucket.audit.id
}

output "audit_bucket_arn" {
  value = aws_s3_bucket.audit.arn
}

output "application_secret_arn" {
  value = aws_secretsmanager_secret.application.arn
}
