variable "aws_region" {
  description = "AWS region used by SecureCloudOps"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the SecureCloudOps VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period"
  type        = number
  default     = 30
}

variable "allowed_client_cidr" {
  description = "IPv4 CIDR permitted to reach the HTTPS load balancer"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_client_cidr))
    error_message = "allowed_client_cidr must be a valid IPv4 CIDR block (prefer a /32)."
  }
}

variable "acm_certificate_arn" {
  description = "Issued ACM certificate ARN in us-east-1 for the HTTPS listener"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/[0-9a-fA-F-]+$", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must identify an ACM certificate in us-east-1."
  }
}

variable "app_instance_type" {
  description = "EC2 instance type for the application nodes"
  type        = string
  default     = "t3.micro"
}

variable "enable_security_test_instance" {
  description = "Create the private SSM-managed defensive validation instance"
  type        = bool
  default     = true
}
