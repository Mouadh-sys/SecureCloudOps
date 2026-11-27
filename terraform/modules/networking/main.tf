data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:Available zones are discovered dynamically to remain compatible with the Academy account's supported AZs.
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  common_tags = merge(var.tags, {
    Module = "networking"
  })
  interface_endpoint_services = toset(concat(
    ["ssm", "ssmmessages", "ec2messages", "logs"],
    var.enable_secrets_manager_endpoint ? ["secretsmanager"] : []
  ))
}

resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11:VPC Flow Logs are configured in the monitoring module and deliver directly to the audit S3 bucket.
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = var.vpc_name
  })
}

resource "aws_default_security_group" "this" {
  vpc_id  = aws_vpc.this.id
  ingress = []
  egress  = []
  tags    = merge(local.common_tags, { Name = "${var.vpc_name}-default" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.vpc_name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "application" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-application-${count.index + 1}"
    Tier = "application"
  })
}

resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-database-${count.index + 1}"
    Tier = "database"
  })
}

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 30)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-management"
    Tier = "management"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.vpc_name}-private" })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "application" {
  count          = 2
  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = 2
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "management" {
  subnet_id      = aws_subnet.management.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-s3-endpoint" })
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.vpc_name}-endpoints-"
  description = "HTTPS access to approved private AWS service endpoints"
  vpc_id      = aws_vpc.this.id
  ingress     = []
  egress      = []

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-endpoints" })
}

resource "aws_security_group" "security_test" {
  #checkov:skip=CKV2_AWS_5:Attached to the optional validation instance through the root workload module.
  name_prefix = "${var.vpc_name}-security-test-"
  description = "Restricted access from the defensive validation host to the demo app"
  vpc_id      = aws_vpc.this.id
  ingress     = []
  egress      = []

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-security-test" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.application[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-${each.key}-endpoint" })
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_from_application" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from application instances"
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_from_security_test" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.security_test.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from the isolated security test host"
}

resource "aws_vpc_security_group_egress_rule" "application_to_endpoints" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS to approved private AWS service endpoints"
}

resource "aws_vpc_security_group_egress_rule" "security_test_to_endpoints" {
  security_group_id            = aws_security_group.security_test.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS to approved private AWS service endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Application traffic from the ALB"
}

resource "aws_vpc_security_group_ingress_rule" "application_from_security_test" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.security_test.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Controlled private health and security validation"
}

resource "aws_vpc_security_group_egress_rule" "application_to_s3" {
  security_group_id = aws_security_group.application.id
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS to the S3 gateway endpoint"
}

resource "aws_vpc_security_group_egress_rule" "security_test_to_application" {
  security_group_id            = aws_security_group.security_test.id
  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  description                  = "Controlled private validation of the demo application"
}

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:Attached to the ALB through the root workload module.
  name_prefix = "${var.vpc_name}-alb-"
  description = "Public HTTPS ingress for the application load balancer"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  egress {
    description = "Application tier HTTPS listener traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [cidrsubnet(var.vpc_cidr, 8, 10), cidrsubnet(var.vpc_cidr, 8, 11)]
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-alb" })
}

resource "aws_security_group" "application" {
  #checkov:skip=CKV2_AWS_5:Attached to the application instances through the root workload module.
  name_prefix = "${var.vpc_name}-application-"
  description = "Application tier accepts traffic only from the load balancer"
  vpc_id      = aws_vpc.this.id
  ingress     = []
  egress      = []

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-application" })
}

resource "aws_security_group" "database" {
  #checkov:skip=CKV2_AWS_5:This staged Security Group is unattached because the baseline intentionally deploys no database.
  name_prefix = "${var.vpc_name}-database-"
  description = "Database tier accepts traffic only from the application tier"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  egress = []

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-database" })
}
