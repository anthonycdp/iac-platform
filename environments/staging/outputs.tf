# Staging Outputs
output "vpc_id" { value = module.networking.vpc_id }
output "alb_dns_name" { value = module.compute.alb_dns_name }
output "rds_endpoint" { value = module.database.endpoint; sensitive = true }
output "environment_info" {
  value = { name = var.environment, region = var.aws_region, project = var.project_name }
}
