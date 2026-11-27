output "application_role_arn" {
  value = data.aws_iam_instance_profile.application.role_arn
}

output "application_instance_profile_name" {
  value = data.aws_iam_instance_profile.application.name
}
