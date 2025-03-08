# =============================================================================
# Security Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "application_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "enable_waf" {
  description = "Enable WAF Web ACL"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF"
  type        = number
  default     = 2000
}

variable "waf_log_destination_arn" {
  description = "ARN for WAF logs destination"
  type        = string
  default     = ""
}

variable "enable_budgets" {
  description = "Enable AWS Budgets"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 100
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
