# =============================================================================
# Production Environment Variables
# =============================================================================

project_name   = "iac-platform"
environment    = "prod"
aws_region     = "us-east-1"

vpc_cidr               = "10.2.0.0/16"
public_subnet_cidrs    = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs   = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
database_subnet_cidrs  = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]

allowed_http_cidrs = ["0.0.0.0/0"]
allowed_ssh_cidrs  = ["10.0.0.0/8"]

database_engine         = "postgres"
database_engine_version = "15.4"
database_name           = "app_prod"

application_port = 8080

alarm_email = "prod-oncall@example.com"

budget_alert_emails = ["prod-team@example.com", "finance@example.com", "ops@example.com"]
