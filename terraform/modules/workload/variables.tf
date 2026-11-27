variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "application_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "management_subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "application_security_group_id" {
  type = string
}

variable "security_test_security_group_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "application_log_group_name" {
  type = string
}

variable "security_topic_arn" {
  type = string
}

variable "acm_certificate_arn" {
  description = "Issued ACM certificate ARN in the ALB's region"
  type        = string
}

variable "app_instance_type" {
  description = "Instance type used for each application node"
  type        = string
  default     = "t3.micro"
}

variable "enable_security_test_instance" {
  description = "Create the private defensive validation instance"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
