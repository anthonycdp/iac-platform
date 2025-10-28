# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# This file provides the backend configuration template for remote state
# management. Copy and customize for your specific environment.
#
# Usage:
#   terraform init \
#     -backend-config="bucket=YOUR-TFSTATE-BUCKET" \
#     -backend-config="region=us-east-1" \
#     -backend-config="dynamodb_table=terraform-state-lock"
#
# For each environment, the key is automatically set based on the
# environment directory structure:
#   - dev:     environments/dev/terraform.tfstate
#   - staging: environments/staging/terraform.tfstate
#   - prod:    environments/prod/terraform.tfstate

# -----------------------------------------------------------------------------
# S3 Backend Configuration Template
# -----------------------------------------------------------------------------
# Uncomment and customize the following block in your environment:

# terraform {
#   backend "s3" {
#     # S3 bucket for storing state files
#     bucket = "your-terraform-state-bucket"
#
#     # State file path within the bucket (set per environment)
#     key = "environments/dev/terraform.tfstate"
#
#     # AWS region where the S3 bucket is located
#     region = "us-east-1"
#
#     # DynamoDB table for state locking
#     dynamodb_table = "terraform-state-lock"
#
#     # Enable server-side encryption
#     encrypt = true
#
#     # Enable versioning (must be enabled on the S3 bucket)
#     # This is configured on the bucket itself
#   }
# }

# -----------------------------------------------------------------------------
# Terraform Cloud Backend Configuration (Alternative)
# -----------------------------------------------------------------------------
# For teams using Terraform Cloud:

# terraform {
#   cloud {
#     organization = "your-organization"
#
#     workspaces {
#       name = "iac-platform-dev"
#     }
#   }
# }
