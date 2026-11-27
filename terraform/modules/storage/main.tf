data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id            = data.aws_caller_identity.current.account_id
  documents_bucket_name = "securecloudops-documents-${local.account_id}-${var.environment}"
  audit_bucket_name     = "securecloudops-audit-${local.account_id}-${var.environment}"
  documents_bucket_arn  = "arn:aws:s3:::${local.documents_bucket_name}"
  audit_bucket_arn      = "arn:aws:s3:::${local.audit_bucket_name}"
  common_tags           = merge(var.tags, { Module = "storage" })
}

data "aws_iam_policy_document" "data_key" {
  #checkov:skip=CKV_AWS_109:KMS account-root delegation is required for IAM-based key use and is scoped to this key's policy.
  #checkov:skip=CKV_AWS_111:KMS account-root delegation is required for IAM-based key use and is scoped to this key's policy.
  #checkov:skip=CKV_AWS_356:KMS key policies require Resource "*" to denote the key to which this policy is attached.
  statement {
    sid    = "EnableAccountIAMPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailToEncryptLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${local.account_id}:trail/securecloudops-${var.environment}"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsToUseKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.region}:${local.account_id}:log-group:/securecloudops/${var.environment}/*",
        "arn:aws:logs:${data.aws_region.current.region}:${local.account_id}:log-group:/aws/lambda/securecloudops-${var.environment}-*",
      ]
    }
  }
}

resource "aws_kms_key" "data" {
  description             = "SecureCloudOps customer-managed data encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.data_key.json

  tags = merge(local.common_tags, { Name = "securecloudops-data-key" })
}

resource "aws_kms_alias" "data" {
  name          = "alias/securecloudops-data"
  target_key_id = aws_kms_key.data.key_id
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = local.documents_bucket_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = local.documents_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = local.documents_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = local.documents_bucket_name

  depends_on = [aws_s3_bucket_versioning.documents]

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "documents" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [local.documents_bucket_arn, "${local.documents_bucket_arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "documents" {
  bucket = local.documents_bucket_name
  policy = data.aws_iam_policy_document.documents.json

  depends_on = [aws_s3_bucket_public_access_block.documents]
}

resource "aws_s3_bucket_public_access_block" "audit" {
  bucket                  = local.audit_bucket_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = local.audit_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = local.audit_bucket_name
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_secretsmanager_secret" "application" {
  #checkov:skip=CKV2_AWS_57:This is an empty placeholder; rotation requires an application and rotation Lambda that the lab baseline does not deploy.
  name                    = "securecloudops/${var.environment}/application"
  description             = "Placeholder for SecureCloudOps application credentials"
  kms_key_id              = aws_kms_key.data.arn
  recovery_window_in_days = 7

  tags = merge(local.common_tags, { Name = "securecloudops-application-secret" })
}
