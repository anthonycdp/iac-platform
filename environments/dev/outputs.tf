# =============================================================================
# Development Environment - Outputs
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.database.endpoint
  sensitive   = true
}

output "environment_info" {
  description = "Environment information"
  value = {
    name       = var.environment
    region     = var.aws_region
    project    = var.project_name
    created_at = timestamp()
  }
}
