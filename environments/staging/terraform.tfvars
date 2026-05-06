# =============================================================================
# Staging Environment Variables
# =============================================================================

project_name = "iac-platform"
environment  = "staging"
aws_region   = "us-east-1"

vpc_cidr              = "10.1.0.0/16"
public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
database_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

allowed_http_cidrs = ["0.0.0.0/0"]
allowed_ssh_cidrs  = ["10.0.0.0/8"]

database_engine         = "postgres"
database_engine_version = "15.4"
database_name           = "app_staging"

application_port = 8080

alarm_email = "staging-team@example.com"

budget_alert_emails = ["staging-team@example.com", "finance@example.com"]
