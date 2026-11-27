data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [var.audit_bucket_arn]
  }
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${var.audit_bucket_arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "VpcFlowLogsAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [var.audit_bucket_arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid    = "VpcFlowLogsWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${var.audit_bucket_arn}/flowlogs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = var.audit_bucket_name
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_flow_log" "vpc" {
  log_destination      = "${var.audit_bucket_arn}/flowlogs"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

resource "aws_cloudwatch_log_group" "application" {
  #checkov:skip=CKV_AWS_338:30-day retention limits storage cost in the transient Academy environment.
  name              = "/securecloudops/${var.environment}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(var.tags, { Module = "monitoring" })
}

resource "aws_cloudwatch_log_group" "security" {
  #checkov:skip=CKV_AWS_338:30-day retention limits storage cost in the transient Academy environment.
  name              = "/securecloudops/${var.environment}/security"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(var.tags, { Module = "monitoring" })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  #checkov:skip=CKV_AWS_338:30-day retention limits storage cost in the transient Academy environment.
  name              = "/securecloudops/${var.environment}/vpc-flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(var.tags, { Module = "monitoring" })
}

resource "aws_cloudtrail" "this" {
  #checkov:skip=CKV_AWS_252:Security findings use the dedicated EventBridge-to-SNS topic; CloudTrail log-delivery notifications would add noise.
  #checkov:skip=CKV2_AWS_10:CloudTrail delivers to S3 because this lab cannot create a dedicated CloudWatch Logs role.
  name                          = "securecloudops-${var.environment}"
  s3_bucket_name                = var.audit_bucket_name
  s3_key_prefix                 = "cloudtrail"
  kms_key_id                    = var.kms_key_arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = merge(var.tags, { Module = "monitoring" })
}

