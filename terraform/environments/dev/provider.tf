provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SecureCloudOps"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}