variable "environment" {
  type = string
}

variable "security_log_group_name" {
  type = string
}

variable "security_log_group_arn" {
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
