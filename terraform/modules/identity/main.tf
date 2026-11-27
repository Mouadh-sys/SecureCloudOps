data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "application" {
  name               = "SecureCloudOps-${var.environment}-ApplicationRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = merge(var.tags, { Module = "identity" })
}

data "aws_iam_policy_document" "application" {
  statement {
    sid       = "DocumentBucketAccess"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [var.documents_bucket_arn, "${var.documents_bucket_arn}/*"]
  }

  statement {
    sid       = "KMSDataAccess"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
  }

  statement {
    sid       = "ApplicationSecretAccess"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.application_secret_arn]
  }
}

resource "aws_iam_policy" "application" {
  name   = "SecureCloudOps-${var.environment}-ApplicationPolicy"
  policy = data.aws_iam_policy_document.application.json
}

resource "aws_iam_role_policy_attachment" "application" {
  role       = aws_iam_role.application.name
  policy_arn = aws_iam_policy.application.arn
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.application.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "application" {
  name = "SecureCloudOps-${var.environment}-ApplicationProfile"
  role = aws_iam_role.application.name
}
