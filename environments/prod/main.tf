# =============================================================================
# Production Environment Configuration
# =============================================================================
# This configuration deploys the production environment with maximum
# availability, security, and monitoring settings.

terraform {
  backend "s3" {
    key = "environments/prod/terraform.tfstate"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Criticality = "High"
  }
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}

# -----------------------------------------------------------------------------
# Networking Module
# -----------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = local.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = false  # Multi-AZ NAT for high availability
  enable_flow_logs   = true
  flow_logs_retention_days = 90

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Storage Module
# -----------------------------------------------------------------------------

module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
  environment = var.environment
  kms_key_id  = module.security.kms_key_id

  enable_versioning = true
  encryption_type   = "aws:kms"
  logs_retention_days = 365
  backup_retention_days = 365

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Module
# -----------------------------------------------------------------------------

module "security" {
  source = "../../modules/security"

  name_prefix        = local.name_prefix
  environment        = var.environment
  region             = var.aws_region
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = var.vpc_cidr
  allowed_http_cidrs = var.allowed_http_cidrs
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
  application_port   = var.application_port

  enable_waf = true
  waf_rate_limit = 5000
  waf_log_destination_arn = module.storage.logs_bucket_arn
  enable_budgets = true
  monthly_budget_amount = 500
  budget_alert_emails = var.budget_alert_emails

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Database Module
# -----------------------------------------------------------------------------

module "database" {
  source = "../../modules/database"

  name_prefix       = local.name_prefix
  environment       = var.environment
  subnet_ids        = module.networking.database_subnet_ids
  security_group_id = module.security.database_security_group_id
  kms_key_id        = module.security.kms_key_id

  engine            = var.database_engine
  engine_version    = var.database_engine_version
  instance_class    = "db.r6g.large"  # Production-grade instance
  database_name     = var.database_name
  multi_az          = true  # Multi-AZ for high availability
  allocated_storage = 100
  max_allocated_storage = 500

  backup_retention_period = 30
  performance_insights_enabled = true
  monitoring_interval = 60
  create_read_replica = true

  alarm_actions = [module.monitoring.sns_topic_arn]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group (created early to avoid circular dependency)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${local.name_prefix}/application"
  retention_in_days = 90

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-application-logs"
  })
}

# -----------------------------------------------------------------------------
# Compute Module
# -----------------------------------------------------------------------------

module "compute" {
  source = "../../modules/compute"

  name_prefix        = local.name_prefix
  environment        = var.environment
  region             = var.aws_region
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.compute_security_group_id

  ami_id              = data.aws_ami.amazon_linux.id
  instance_type       = "m6i.large"
  asg_min_size        = 3
  asg_max_size        = 10
  asg_desired_capacity = 3

  logs_bucket_name = module.storage.alb_logs_bucket_name
  data_bucket_arn  = module.storage.data_bucket_arn
  log_group_name   = aws_cloudwatch_log_group.application.name
  database_endpoint = module.database.endpoint
  database_name     = module.database.database_name

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Monitoring Module
# -----------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix          = local.name_prefix
  region               = var.aws_region
  alert_email          = var.alarm_email
  log_retention_days   = 90
  alb_name_suffix      = module.compute.alb_arn_suffix
  config_bucket_name   = module.storage.bucket_names.logs
  existing_log_group_name = aws_cloudwatch_log_group.application.name

  enable_billing_alerts = true
  billing_threshold    = 500

  alb_response_time_threshold = 0.5
  alb_5xx_threshold = 5

  tags = local.common_tags
}
