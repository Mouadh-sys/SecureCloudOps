data "aws_caller_identity" "current" {}

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
    actions   = ["s3:PutObject"]
    resources = ["${var.audit_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = var.audit_bucket_name
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/securecloudops/${var.environment}/application"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Module = "monitoring" })
}

resource "aws_cloudwatch_log_group" "security" {
  name              = "/securecloudops/${var.environment}/security"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Module = "monitoring" })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/securecloudops/${var.environment}/vpc-flow-logs"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Module = "monitoring" })
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "SecureCloudOps-${var.environment}-VpcFlowLogs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json
  tags               = merge(var.tags, { Module = "monitoring" })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "SecureCloudOps-${var.environment}-VpcFlowLogsPolicy"
  role = aws_iam_role.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id
}

resource "aws_cloudtrail" "this" {
  name                          = "securecloudops-${var.environment}"
  s3_bucket_name                = var.audit_bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = merge(var.tags, { Module = "monitoring" })
}

resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "securecloudops-${var.environment}"
  type          = "ACCOUNT"
  tags          = merge(var.tags, { Module = "monitoring" })
}
