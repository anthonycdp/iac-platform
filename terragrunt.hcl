# =============================================================================
# Root Terragrunt Configuration
# =============================================================================
# This file contains common configuration that can be included in all child
# Terragrunt configurations for DRY infrastructure management.

# -----------------------------------------------------------------------------
# Remote State Configuration
# -----------------------------------------------------------------------------
# Generates backend.tf automatically for each module

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = getenv("TF_STATE_BUCKET", "${get_aws_account_id()}-terraform-state")
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = getenv("AWS_REGION", "us-east-1")
    encrypt        = true
    dynamodb_table = getenv("TF_LOCK_TABLE", "terraform-state-lock")

    # Enable versioning on the bucket (bucket must have versioning enabled)
    skip_metadata_api_check     = false
    skip_region_validation      = false
    skip_credentials_validation = false
  }
}

# -----------------------------------------------------------------------------
# Generate Common Provider Configuration
# -----------------------------------------------------------------------------

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project       = var.project_name
      Environment   = var.environment
      ManagedBy     = "Terragrunt"
      Repository    = "iac-platform"
    }
  }
}

provider "random" {}
EOF
}

# -----------------------------------------------------------------------------
# Generate Required Providers
# -----------------------------------------------------------------------------

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
EOF
}

# -----------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------

inputs = {
  project_name = get_env("PROJECT_NAME", "iac-platform")
  aws_region   = get_env("AWS_REGION", "us-east-1")
}

# -----------------------------------------------------------------------------
# Hooks
# -----------------------------------------------------------------------------

terraform {
  before_hook "before_apply" {
    commands = ["apply"]
    execute  = ["echo", "Starting Terraform apply at $(date)"]
  }

  after_hook "after_apply" {
    commands     = ["apply"]
    execute      = ["echo", "Terraform apply completed at $(date)"]
    run_on_error = true
  }

  before_hook "before_plan" {
    commands = ["plan"]
    execute  = ["echo", "Starting Terraform plan at $(date)"]
  }

  after_hook "after_plan" {
    commands     = ["plan"]
    execute      = ["echo", "Terraform plan completed at $(date)"]
    run_on_error = true
  }
}
