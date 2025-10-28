# =============================================================================
# Global Variables
# =============================================================================
# These variables are used across all environments and modules.
# Environment-specific values should be defined in terraform.tfvars files.

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used in resource naming and tagging"
  type        = string
  default     = "iac-platform"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 4-30 characters, lowercase letters, numbers, and hyphens only, must start with a letter."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "AWS region must be a valid format (e.g., us-east-1, eu-west-1)."
  }
}

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

# -----------------------------------------------------------------------------
# Compute Configuration
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for compute resources"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum size for the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size for the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired capacity for the Auto Scaling Group"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "database_instance_class" {
  description = "Instance class for RDS database"
  type        = string
  default     = "db.t3.micro"
}

variable "database_engine" {
  description = "Database engine type"
  type        = string
  default     = "postgres"
}

variable "database_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "application"
}

variable "database_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "database_multi_az" {
  description = "Enable Multi-AZ deployment for the database"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------

variable "s3_bucket_names" {
  description = "Map of S3 bucket names and their configurations"
  type = map(object({
    versioning    = bool
    encryption    = bool
    public_access = bool
  }))
  default = {
    data = {
      versioning    = true
      encryption    = true
      public_access = false
    }
    logs = {
      versioning    = false
      encryption    = true
      public_access = false
    }
  }
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alerting"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_waf" {
  description = "Enable AWS WAF for web application firewall protection"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Cost Management
# -----------------------------------------------------------------------------

variable "enable_cost_alerts" {
  description = "Enable AWS Budgets cost alerts"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 100
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = []
}
