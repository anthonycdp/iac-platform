# =============================================================================
# Environment-Level Terragrunt Configuration
# =============================================================================
# This file contains environment-specific configuration and is the parent
# configuration for all modules within this environment.

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# -----------------------------------------------------------------------------
# Environment-Specific Variables
# -----------------------------------------------------------------------------

locals {
  environment = basename(get_terragrunt_dir())
  account_id  = get_aws_account_id()
  region      = get_env("AWS_REGION", "us-east-1")

  # Environment-specific settings
  env_config = {
    dev = {
      instance_type       = "t3.micro"
      asg_min_size        = 1
      asg_max_size        = 2
      db_instance_class   = "db.t3.micro"
      db_multi_az         = false
      single_nat_gateway  = true
      retention_days      = 7
      monthly_budget      = 50
    }
    staging = {
      instance_type       = "t3.small"
      asg_min_size        = 2
      asg_max_size        = 4
      db_instance_class   = "db.t3.small"
      db_multi_az         = true
      single_nat_gateway  = true
      retention_days      = 14
      monthly_budget      = 200
    }
    prod = {
      instance_type       = "t3.medium"
      asg_min_size        = 3
      asg_max_size        = 10
      db_instance_class   = "db.t3.medium"
      db_multi_az         = true
      single_nat_gateway  = false
      retention_days      = 30
      monthly_budget      = 500
    }
  }

  config = local.env_config[local.environment]
}

# Generate environment variables file
generate "env_vars" {
  path      = "env_vars.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "${local.environment}"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "${local.region}"
}
EOF
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

dependencies {
  paths = []
}

# -----------------------------------------------------------------------------
# Skip certain operations
# -----------------------------------------------------------------------------

skip = false

# -----------------------------------------------------------------------------
# Retry Configuration
# -----------------------------------------------------------------------------

retry_max_attempts     = 3
retry_sleep_interval_sec = 5
