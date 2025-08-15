# =============================================================================
# Storage Module - Outputs
# =============================================================================

output "bucket_arns" {
  description = "Map of bucket ARNs"
  value = {
    data     = aws_s3_bucket.data.arn
    logs     = aws_s3_bucket.logs.arn
    alb_logs = aws_s3_bucket.alb_logs.arn
    backup   = aws_s3_bucket.backup.arn
  }
}

output "bucket_names" {
  description = "Map of bucket names"
  value = {
    data     = aws_s3_bucket.data.id
    logs     = aws_s3_bucket.logs.id
    alb_logs = aws_s3_bucket.alb_logs.id
    backup   = aws_s3_bucket.backup.id
  }
}

output "data_bucket_id" {
  description = "ID of the data bucket"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_arn" {
  description = "ARN of the data bucket"
  value       = aws_s3_bucket.data.arn
}

output "logs_bucket_id" {
  description = "ID of the logs bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs bucket"
  value       = aws_s3_bucket.logs.arn
}

output "alb_logs_bucket_name" {
  description = "Name of the ALB logs bucket"
  value       = aws_s3_bucket.alb_logs.id
}

output "backup_bucket_id" {
  description = "ID of the backup bucket"
  value       = aws_s3_bucket.backup.id
}

output "backup_bucket_arn" {
  description = "ARN of the backup bucket"
  value       = aws_s3_bucket.backup.arn
}
