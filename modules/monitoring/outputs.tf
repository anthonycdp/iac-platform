# =============================================================================
# Monitoring Module - Outputs
# =============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.name
}

output "log_group_name" {
  description = "Name of the application CloudWatch log group"
  value       = var.existing_log_group_name != "" ? var.existing_log_group_name : aws_cloudwatch_log_group.application[0].name
}

output "log_group_arn" {
  description = "ARN of the application CloudWatch log group"
  value       = var.existing_log_group_name != "" ? null : aws_cloudwatch_log_group.application[0].arn
}

output "system_log_group_name" {
  description = "Name of the system CloudWatch log group"
  value       = aws_cloudwatch_log_group.system.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = aws_config_configuration_recorder.main.name
}

output "alarm_arns" {
  description = "Map of CloudWatch alarm ARNs"
  value = {
    alb_high_response_time = aws_cloudwatch_metric_alarm.alb_high_response_time.arn
    alb_5xx_errors         = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
    alb_unhealthy_targets  = aws_cloudwatch_metric_alarm.alb_unhealthy_targets.arn
  }
}
