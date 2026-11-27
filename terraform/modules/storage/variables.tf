variable "environment" {
  type = string
}

variable "noncurrent_version_expiration_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}
