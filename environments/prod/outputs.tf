# Production Outputs
output "vpc_id" { value = module.networking.vpc_id }
output "alb_dns_name" { value = module.compute.alb_dns_name }
output "rds_endpoint" { value = module.database.endpoint; sensitive = true }
output "rds_read_replica_endpoint" { value = module.database.read_replica_endpoint; sensitive = true }
output "waf_web_acl_arn" { value = module.security.waf_web_acl_arn }
output "environment_info" {
  value = {
    name        = var.environment
    region      = var.aws_region
    project     = var.project_name
    criticality = "High"
  }
}
