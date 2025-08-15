# =============================================================================
# Storage Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on data bucket"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Server-side encryption type (AES256 or aws:kms)"
  type        = string
  default     = "aws:kms"
}

variable "ia_transition_days" {
  description = "Days before transitioning to Standard-IA"
  type        = number
  default     = 90
}

variable "glacier_transition_days" {
  description = "Days before transitioning to Glacier"
  type        = number
  default     = 180
}

variable "noncurrent_version_expiration_days" {
  description = "Days before expiring noncurrent versions"
  type        = number
  default     = 90
}

variable "logs_retention_days" {
  description = "Days to retain logs"
  type        = number
  default     = 90
}

variable "backup_retention_days" {
  description = "Days to retain backups"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
