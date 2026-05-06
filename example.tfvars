# =============================================================================
# Example Terraform Variables
# =============================================================================
# Copy this file to terraform.tfvars and customize for your environment.
# DO NOT commit terraform.tfvars with sensitive values!

# Project Configuration
project_name = "iac-platform"
environment  = "dev"
aws_region   = "us-east-1"

# Networking
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# Security - Update these for your environment
allowed_http_cidrs = ["0.0.0.0/0"]
allowed_ssh_cidrs  = ["10.0.0.0/8"] # Restrict to your IP or VPN

# Database
database_engine         = "postgres"
database_engine_version = "15.4"
database_name           = "application"

# Application
application_port = 8080

# Monitoring
alarm_email = "your-team@example.com"

# Budget
budget_alert_emails = ["your-team@example.com"]
