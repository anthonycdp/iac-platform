# =============================================================================
# OPA Policy: Required Tags
# =============================================================================
# Enforces mandatory tagging on all resources.

package terraform.tagging

import input as tfplan

# Required tags for all resources
required_tags := {"Environment", "Project", "ManagedBy"}

# Default deny
default allow := false

# Allow if all resources have required tags
allow if {
    every resource in tagged_resources {
        has_required_tags(resource)
    }
}

# Check if resource has all required tags
has_required_tags(resource) {
    every tag in required_tags {
        tag in object.keys(resource.change.after.tags)
    }
}

# Get resources that should be tagged
tagged_resources[resource] {
    some resource in tfplan.resource_changes
    supports_tags(resource.type)
    "create" in resource.change.actions or "update" in resource.change.actions
}

# Resource types that support tags
supports_tags(type) {
    type in [
        "aws_instance",
        "aws_vpc",
        "aws_subnet",
        "aws_security_group",
        "aws_db_instance",
        "aws_s3_bucket",
        "aws_lb",
        "aws_autoscaling_group",
        "aws_ebs_volume",
        "aws_iam_role",
        "aws_lambda_function",
        "aws_cloudwatch_log_group",
        "aws_dynamodb_table",
        "aws_elasticache_cluster",
        "aws_ecs_cluster",
        "aws_ecs_service"
    ]
}

# Violation messages
violation[msg] {
    some resource in tagged_resources
    not has_required_tags(resource)
    msg := sprintf("Resource %s missing required tags", [resource.address])
}

violation[msg] {
    some resource in tagged_resources
    some tag in required_tags
    not tag in object.keys(resource.change.after.tags)
    msg := sprintf("Resource %s missing tag: %s", [resource.address, tag])
}
