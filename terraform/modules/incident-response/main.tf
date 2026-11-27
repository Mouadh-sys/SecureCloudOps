data "aws_caller_identity" "current" {}

data "aws_archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.root}/../../../lambda/incident-response/handler.py"
  output_path = "${path.module}/incident-response.zip"
}

resource "aws_sns_topic" "security" {
  name = "securecloudops-${var.environment}-security-findings"
  tags = merge(var.tags, { Module = "incident-response" })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/securecloudops-${var.environment}-incident-response"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { Module = "incident-response" })
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "SecureCloudOps-${var.environment}-IncidentResponse"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = merge(var.tags, { Module = "incident-response" })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda" {
  name = "SecureCloudOps-${var.environment}-IncidentResponsePolicy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${var.security_log_group_arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.security.arn
      }
    ]
  })
}

resource "aws_lambda_function" "incident_response" {
  filename         = data.aws_archive_file.lambda.output_path
  source_code_hash = data.aws_archive_file.lambda.output_base64sha256
  function_name    = "securecloudops-${var.environment}-incident-response"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN      = aws_sns_topic.security.arn
      SECURITY_LOG_GROUP = var.security_log_group_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda
  ]

  tags = merge(var.tags, { Module = "incident-response" })
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
  target_id = "IncidentResponseLambda"
  arn       = aws_lambda_function.incident_response.arn
}

resource "aws_cloudwatch_event_target" "security_hub" {
  rule      = aws_cloudwatch_event_rule.security_hub.name
  target_id = "IncidentResponseLambda"
  arn       = aws_lambda_function.incident_response.arn
}

resource "aws_lambda_permission" "guardduty" {
  statement_id  = "AllowEventBridgeGuardDuty"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_response.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty.arn
}

resource "aws_lambda_permission" "security_hub" {
  statement_id  = "AllowEventBridgeSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_response.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_hub.arn
}
