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

variable "tags" {
  type    = map(string)
  default = {}
}
