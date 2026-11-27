variable "aws_region" {
  type = string
}

variable "vpc_name" {
  type    = string
  default = "securecloudops-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "allowed_client_cidr" {
  description = "IPv4 CIDR permitted to reach the HTTPS load balancer"
  type        = string
}

variable "enable_secrets_manager_endpoint" {
  description = "Create the private Secrets Manager endpoint when the database workload is enabled"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
