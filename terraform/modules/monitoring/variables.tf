variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "audit_bucket_name" {
  type = string
}

variable "audit_bucket_arn" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
