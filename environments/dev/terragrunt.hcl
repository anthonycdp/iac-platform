# =============================================================================
# Development Environment - Networking Module
# =============================================================================

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "env" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
}

terraform {
  source = "${get_parent_terragrunt_dir()}/..//modules/networking"
}

# -----------------------------------------------------------------------------
# Input Variables
# -----------------------------------------------------------------------------

locals {
  name_prefix = "iac-platform-dev"
  common_tags = {
    Project     = "iac-platform"
    Environment = "dev"
    ManagedBy   = "Terragrunt"
  }
}

inputs = {
  name_prefix           = local.name_prefix
  vpc_cidr              = "10.0.0.0/16"
  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  enable_nat_gateway    = true
  single_nat_gateway    = true
  enable_flow_logs      = true
  tags                  = local.common_tags
}
