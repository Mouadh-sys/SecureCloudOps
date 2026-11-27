variable "environment" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
