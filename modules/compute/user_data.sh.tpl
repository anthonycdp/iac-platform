#!/bin/bash
# =============================================================================
# EC2 User Data Script
# =============================================================================
# This script runs on instance launch to configure the instance.

set -euo pipefail

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting instance configuration..."

# -----------------------------------------------------------------------------
# System Updates
# -----------------------------------------------------------------------------

yum update -y || apt-get update -y

# -----------------------------------------------------------------------------
# Install AWS CloudWatch Agent
# -----------------------------------------------------------------------------

yum install -y amazon-cloudwatch-agent || apt-get install -y amazon-cloudwatch-agent

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWAGENT'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/user-data"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CustomMetrics",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_active", "cpu_usage_idle"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    }
  }
}
CWAGENT

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# -----------------------------------------------------------------------------
# Install Application Dependencies
# -----------------------------------------------------------------------------

# Install common tools
yum install -y git curl wget || apt-get install -y git curl wget

# -----------------------------------------------------------------------------
# Configure Environment Variables
# -----------------------------------------------------------------------------

cat >> /etc/environment << EOF
ENVIRONMENT=${environment}
AWS_REGION=${region}
DATABASE_ENDPOINT=${database_endpoint}
DATABASE_NAME=${database_name}
EOF

echo "Instance configuration completed successfully!"
