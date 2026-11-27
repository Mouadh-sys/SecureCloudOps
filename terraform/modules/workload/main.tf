data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  common_tags = merge(var.tags, {
    Module = "workload"
  })

  app_user_data = templatefile("${path.module}/../../../apps/document-inventory/user-data.sh.tftpl", {
    app_source_base64  = filebase64("${path.module}/../../../apps/document-inventory/app.py")
    region             = var.aws_region
    log_group_name     = var.application_log_group_name
  })
}

resource "aws_lb" "application" {
  #checkov:skip=CKV_AWS_91:ALB access logs require a dedicated SSE-S3 bucket; the protected audit bucket uses KMS encryption.
  #checkov:skip=CKV2_AWS_28:WAF adds recurring cost; this synthetic demo restricts access to the operator-supplied client CIDR.
  name                       = "securecloudops-${var.environment}"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = var.public_subnet_ids
  security_groups            = [var.alb_security_group_id]
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = merge(local.common_tags, { Name = "securecloudops-${var.environment}" })
}

resource "aws_lb_target_group" "application" {
  name        = "securecloudops-${var.environment}-app"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, { Name = "securecloudops-${var.environment}-app" })
}

resource "aws_instance" "application" {
  #checkov:skip=CKV_AWS_126:Standard EC2 metrics and ALB health metrics avoid detailed-monitoring charges in the Learner Lab.
  count = 2

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.app_instance_type
  ebs_optimized               = true
  subnet_id                   = var.application_subnet_ids[count.index]
  vpc_security_group_ids      = [var.application_security_group_id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false
  user_data                   = local.app_user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    kms_key_id  = var.kms_key_arn
    volume_size = 8
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = "scops-app-0${count.index + 1}"
    Role = "application"
  })
}

resource "aws_lb_target_group_attachment" "application" {
  count = 2

  target_group_arn = aws_lb_target_group.application.arn
  target_id        = aws_instance.application[count.index].id
  port             = 8080
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "securecloudops-${var.environment}-unhealthy-targets"
  alarm_description   = "One or more application targets are unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.security_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.application.arn_suffix
    TargetGroup  = aws_lb_target_group.application.arn_suffix
  }

  tags = local.common_tags
}

resource "aws_instance" "security_test" {
  #checkov:skip=CKV_AWS_126:Standard EC2 metrics avoid detailed-monitoring charges for this optional Learner Lab host.
  count = var.enable_security_test_instance ? 1 : 0

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.app_instance_type
  ebs_optimized               = true
  subnet_id                   = var.management_subnet_id
  vpc_security_group_ids      = [var.security_test_security_group_id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false
  user_data                   = "#!/bin/bash\nset -euo pipefail\nsystemctl enable --now amazon-ssm-agent\n"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    kms_key_id  = var.kms_key_arn
    volume_size = 8
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = "scops-sec-01"
    Role = "defensive-validation"
  })
}
