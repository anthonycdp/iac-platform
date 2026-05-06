# =============================================================================
# Monitoring Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for encrypting alert topics"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "alb_name_suffix" {
  description = "ALB name suffix for metric dimensions"
  type        = string
}

variable "alb_response_time_threshold" {
  description = "Threshold for ALB response time alarm (seconds)"
  type        = number
  default     = 1.0
}

variable "alb_5xx_threshold" {
  description = "Threshold for ALB 5XX error count"
  type        = number
  default     = 10
}

variable "enable_billing_alerts" {
  description = "Enable billing alert alarms"
  type        = bool
  default     = true
}

variable "billing_threshold" {
  description = "Billing threshold in USD"
  type        = number
  default     = 100
}

variable "config_bucket_name" {
  description = "S3 bucket name for AWS Config"
  type        = string
}

variable "existing_log_group_name" {
  description = "Name of an existing CloudWatch log group to use (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
