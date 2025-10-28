# =============================================================================
# Provider Configuration
# =============================================================================
# Base provider configuration that can be extended by environment-specific
# configurations. This file defines the AWS provider with common settings.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project       = var.project_name
      Environment   = var.environment
      ManagedBy     = "Terraform"
      Repository    = "https://github.com/example/infrastructure"
      Documentation = "See README.md for details"
    }
  }
}

# Provider for ACM certificate validation (us-east-1 for CloudFront)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
