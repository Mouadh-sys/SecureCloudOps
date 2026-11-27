output "cloudtrail_arn" {
  value = aws_cloudtrail.this.arn
}

output "application_log_group_name" {
  value = aws_cloudwatch_log_group.application.name
}

output "security_log_group_name" {
  value = aws_cloudwatch_log_group.security.name
}

output "security_log_group_arn" {
  value = aws_cloudwatch_log_group.security.arn
}
