data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  common_tags = {
    Project     = "SecureCloudOps"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "networking" {
  source     = "../../modules/networking"
  aws_region = var.aws_region
  vpc_name   = "securecloudops-vpc"
  vpc_cidr   = var.vpc_cidr
  tags       = local.common_tags
}

module "storage" {
  source      = "../../modules/storage"
  environment = var.environment
  tags        = local.common_tags
}

module "identity" {
  source                = "../../modules/identity"
  instance_profile_name = "LabInstanceProfile"
}

module "monitoring" {
  source             = "../../modules/monitoring"
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  audit_bucket_name  = module.storage.audit_bucket_name
  audit_bucket_arn   = module.storage.audit_bucket_arn
  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}

module "incident_response" {
  source             = "../../modules/incident-response"
  environment        = var.environment
  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}