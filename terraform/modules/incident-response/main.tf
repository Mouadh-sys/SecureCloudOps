resource "aws_sns_topic" "security" {
  name = "securecloudops-${var.environment}-security-findings"
  tags = merge(var.tags, { Module = "incident-response" })
}

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
}

resource "aws_sns_topic_policy" "security" {
  arn    = aws_sns_topic.security.arn
  policy = data.aws_iam_policy_document.eventbridge_publish.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/securecloudops-${var.environment}-incident-response"
  retention_in_days = var.log_retention_days
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
