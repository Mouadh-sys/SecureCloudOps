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
  source              = "../../modules/networking"
  aws_region          = var.aws_region
  vpc_name            = "securecloudops-vpc"
  vpc_cidr            = var.vpc_cidr
  allowed_client_cidr = var.allowed_client_cidr
  tags                = local.common_tags
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
  kms_key_arn        = module.storage.kms_key_arn
  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}

module "incident_response" {
  source             = "../../modules/incident-response"
  environment        = var.environment
  kms_key_arn        = module.storage.kms_key_arn
  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}

module "workload" {
  source                          = "../../modules/workload"
  environment                     = var.environment
  aws_region                      = var.aws_region
  vpc_id                          = module.networking.vpc_id
  public_subnet_ids               = module.networking.public_subnet_ids
  application_subnet_ids          = module.networking.application_subnet_ids
  management_subnet_id            = module.networking.management_subnet_id
  alb_security_group_id           = module.networking.alb_security_group_id
  application_security_group_id   = module.networking.application_security_group_id
  security_test_security_group_id = module.networking.security_test_security_group_id
  instance_profile_name           = module.identity.application_instance_profile_name
  kms_key_arn                     = module.storage.kms_key_arn
  application_log_group_name      = module.monitoring.application_log_group_name
  security_topic_arn              = module.incident_response.sns_topic_arn
  acm_certificate_arn             = var.acm_certificate_arn
  app_instance_type               = var.app_instance_type
  enable_security_test_instance   = var.enable_security_test_instance
  tags                            = local.common_tags
}