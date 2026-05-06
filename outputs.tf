# =============================================================================
# Global Outputs
# =============================================================================
# These outputs provide essential information about the deployed infrastructure.
# They can be referenced by other Terraform configurations or used in CI/CD.

# -----------------------------------------------------------------------------
# Networking Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = module.networking.database_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of NAT gateways"
  value       = module.networking.nat_gateway_public_ips
}

# -----------------------------------------------------------------------------
# Compute Outputs
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.compute.alb_zone_id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.compute.launch_template_id
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = module.database.port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.database.database_name
}

# -----------------------------------------------------------------------------
# Storage Outputs
# -----------------------------------------------------------------------------

output "s3_bucket_arns" {
  description = "ARNs of created S3 buckets"
  value       = module.storage.bucket_arns
}

output "s3_bucket_names" {
  description = "Names of created S3 buckets"
  value       = module.storage.bucket_names
}

# -----------------------------------------------------------------------------
# Security Outputs
# -----------------------------------------------------------------------------

output "security_group_ids" {
  description = "IDs of created security groups"
  value = {
    alb      = module.security.alb_security_group_id
    compute  = module.security.compute_security_group_id
    database = module.security.database_security_group_id
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = module.security.kms_key_arn
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.monitoring.log_group_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

# -----------------------------------------------------------------------------
# Environment Information
# -----------------------------------------------------------------------------

output "environment" {
  description = "Current deployment environment"
  value       = var.environment
}

output "region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "resource_prefix" {
  description = "Prefix used for all resource names"
  value       = "${var.project_name}-${var.environment}"
}
