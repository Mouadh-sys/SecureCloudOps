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

variable "enable_guardduty" {
  description = "Reserved for optional GuardDuty deployment"
  type        = bool
  default     = false
}