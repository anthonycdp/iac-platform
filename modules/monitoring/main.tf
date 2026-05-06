# =============================================================================
# Monitoring Module - Main Resources
# =============================================================================

locals {
  alarm_period_seconds           = 60
  alarm_evaluation_periods       = 2
  alarm_single_evaluation_period = 1
  billing_period_seconds         = 21600
  metric_period_seconds          = 300
  unhealthy_host_threshold       = 0
  dashboard_width_half           = 12
  dashboard_width_full           = 24
  dashboard_height               = 6
}

resource "aws_sns_topic" "alerts" {
  name              = "${var.name_prefix}-alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_log_group" "application" {
  count             = var.existing_log_group_name == "" ? 1 : 0
  name              = "/aws/${var.name_prefix}/application"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-logs"
  })
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/${var.name_prefix}/system"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-system-logs"
  })
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = local.dashboard_width_half
        height = local.dashboard_height
        properties = {
          title   = "EC2 CPU Utilization"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", period = local.metric_period_seconds }]
          ]
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = local.dashboard_width_half
        y      = 0
        width  = local.dashboard_width_half
        height = local.dashboard_height
        properties = {
          title   = "ALB Request Count"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", period = local.metric_period_seconds }]
          ]
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.dashboard_height
        width  = local.dashboard_width_half
        height = local.dashboard_height
        properties = {
          title   = "RDS Connections"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { stat = "Average", period = local.metric_period_seconds }]
          ]
          region = var.region
        }
      },
      {
        type   = "metric"
        x      = local.dashboard_width_half
        y      = local.dashboard_height
        width  = local.dashboard_width_half
        height = local.dashboard_height
        properties = {
          title   = "ALB Target Response Time"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", period = local.metric_period_seconds }]
          ]
          region = var.region
        }
      },
      {
        type   = "log"
        x      = 0
        y      = local.dashboard_height * 2
        width  = local.dashboard_width_full
        height = local.dashboard_height
        properties = {
          title         = "Recent Application Errors"
          logGroupNames = [var.existing_log_group_name != "" ? var.existing_log_group_name : aws_cloudwatch_log_group.application[0].name]
          view          = "table"
          query         = "fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 100"
          region        = var.region
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  alarm_name          = "${var.name_prefix}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = local.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.alb_response_time_threshold
  alarm_description   = "ALB response time exceeds ${var.alb_response_time_threshold}s"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_single_evaluation_period
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = local.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5XX errors exceed ${var.alb_5xx_threshold}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name          = "${var.name_prefix}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = local.alarm_period_seconds
  statistic           = "Average"
  threshold           = local.unhealthy_host_threshold
  alarm_description   = "ALB has unhealthy targets"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_name_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  count               = var.enable_billing_alerts ? 1 : 0
  alarm_name          = "${var.name_prefix}-estimated-charges"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.alarm_single_evaluation_period
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = local.billing_period_seconds
  statistic           = "Maximum"
  threshold           = var.billing_threshold
  alarm_description   = "AWS charges exceed USD ${var.billing_threshold}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = var.tags
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.name_prefix}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.name_prefix}-config-delivery"
  s3_bucket_name = var.config_bucket_name
  sns_topic_arn  = aws_sns_topic.alerts.arn

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
}

resource "aws_iam_role" "config" {
  name = "${var.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name        = "${var.name_prefix}-encrypted-volumes"
  description = "EBS volumes must be encrypted"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_public_read" {
  name        = "${var.name_prefix}-s3-public-read"
  description = "S3 buckets must not be publicly readable"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_ssl" {
  name        = "${var.name_prefix}-s3-ssl"
  description = "S3 buckets must require SSL"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
