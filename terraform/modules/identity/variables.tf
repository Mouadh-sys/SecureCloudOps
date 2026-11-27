variable "environment" {
  type = string
}

variable "documents_bucket_arn" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "application_secret_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
