# Staging variables - same structure as dev
variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "database_subnet_cidrs" { type = list(string) }
variable "allowed_http_cidrs" { type = list(string) }
variable "allowed_ssh_cidrs" { type = list(string) }
variable "database_engine" { type = string }
variable "database_engine_version" { type = string }
variable "database_name" { type = string }
variable "application_port" { type = number }
variable "alarm_email" { type = string }
variable "budget_alert_emails" { type = list(string) }
