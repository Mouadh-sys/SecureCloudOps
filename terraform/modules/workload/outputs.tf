output "load_balancer_dns_name" {
  value = aws_lb.application.dns_name
}

output "load_balancer_arn" {
  value = aws_lb.application.arn
}

output "application_instance_ids" {
  value = aws_instance.application[*].id
}

output "security_test_instance_id" {
  value = try(aws_instance.security_test[0].id, null)
}
