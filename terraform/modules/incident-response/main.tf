resource "aws_sns_topic" "security" {
  name              = "securecloudops-${var.environment}-security-findings"
  kms_master_key_id = "alias/aws/sns"
  tags              = merge(var.tags, { Module = "incident-response" })
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "eventbridge_publish" {
  statement {
    sid    = "AllowGuardDutyEventBridge"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.guardduty.arn]
    }
  }

  statement {
    sid    = "AllowSecurityHubEventBridge"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.security_hub.arn]
    }
  }

  statement {
    sid    = "AllowCloudWatchAlarms"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security.arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudwatch:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:alarm:securecloudops-${var.environment}-*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "security" {
  arn    = aws_sns_topic.security.arn
  policy = data.aws_iam_policy_document.eventbridge_publish.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  #checkov:skip=CKV_AWS_338:30-day retention limits storage cost in the transient Academy environment.
  name              = "/aws/lambda/securecloudops-${var.environment}-incident-response"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = merge(var.tags, { Module = "incident-response" })
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  name        = "securecloudops-${var.environment}-guardduty-findings"
  description = "Route GuardDuty findings to incident response"
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
  tags = merge(var.tags, { Module = "incident-response" })
}

resource "aws_cloudwatch_event_rule" "security_hub" {
  name        = "securecloudops-${var.environment}-security-hub-findings"
  description = "Route Security Hub findings to incident response"
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
  })
  tags = merge(var.tags, { Module = "incident-response" })
}

resource "aws_cloudwatch_event_target" "guardduty" {
  rule      = aws_cloudwatch_event_rule.guardduty.name
  target_id = "SecurityNotifications"
  arn       = aws_sns_topic.security.arn

  depends_on = [aws_sns_topic_policy.security]
}

resource "aws_cloudwatch_event_target" "security_hub" {
  rule      = aws_cloudwatch_event_rule.security_hub.name
  target_id = "SecurityNotifications"
  arn       = aws_sns_topic.security.arn

  depends_on = [aws_sns_topic_policy.security]
}
