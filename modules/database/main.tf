# =============================================================================
# Database Module - Main Resources
# =============================================================================

locals {
  bytes_per_gb                   = 1024 * 1024 * 1024
  storage_alert_threshold_ratio  = 0.2
  cpu_threshold_percent          = 80
  alarm_evaluation_periods       = 2
  alarm_period_seconds           = 300
  password_length                = 32
  performance_insights_retention = 7
  prod_recovery_window_days      = 30
  non_prod_recovery_window_days  = 0
}

resource "aws_db_subnet_group" "main" {
  name       = var.name_prefix
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-subnet-group"
  })
}

resource "aws_db_parameter_group" "main" {
  family = "${var.engine}${var.engine_version_major}"
  name   = "${var.name_prefix}-params"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "master" {
  length           = local.password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.name_prefix}-db-password"
  recovery_window_in_days = var.environment == "prod" ? local.prod_recovery_window_days : local.non_prod_recovery_window_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-password-secret"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.master.result
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    database = var.database_name
  })
}

resource "aws_db_instance" "main" {
  identifier     = "${var.name_prefix}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name           = var.database_name
  username          = var.username
  password          = random_password.master.result
  allocated_storage = var.allocated_storage

  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.security_group_id]
  parameter_group_name    = aws_db_parameter_group.main.name
  multi_az                = var.multi_az
  storage_type            = var.storage_type
  storage_encrypted       = true
  kms_key_id              = var.kms_key_id
  max_allocated_storage   = var.max_allocated_storage
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection       = var.environment == "prod"
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.name_prefix}-final-snapshot" : null
  publicly_accessible       = false
  copy_tags_to_snapshot     = true

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? local.performance_insights_retention : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db"
  })

  lifecycle {
    ignore_changes = [password]
  }
}

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.name_prefix}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = local.alarm_period_seconds
  statistic           = "Average"
  threshold           = local.cpu_threshold_percent
  alarm_description   = "Database CPU usage exceeds ${local.cpu_threshold_percent}%"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "storage_low" {
  alarm_name          = "${var.name_prefix}-db-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = local.alarm_evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = local.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.allocated_storage * local.bytes_per_gb * local.storage_alert_threshold_ratio
  alarm_description   = "Database free storage below ${local.storage_alert_threshold_ratio * 100}%"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "connections_high" {
  alarm_name          = "${var.name_prefix}-db-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = local.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.max_connections_threshold
  alarm_description   = "Database connections exceed ${var.max_connections_threshold}"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0

  identifier                   = "${var.name_prefix}-db-replica"
  replicate_source_db          = aws_db_instance.main.identifier
  instance_class               = var.instance_class
  vpc_security_group_ids       = [var.security_group_id]
  publicly_accessible          = false
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-replica"
  })
}
