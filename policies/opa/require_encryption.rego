# =============================================================================
# OPA Policy: Require Encryption at Rest
# =============================================================================
# This policy ensures all storage resources have encryption enabled.

package terraform.encryption

# Deny RDS instances without encryption
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_db_instance"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    not resource.change.after.storage_encrypted
    message := sprintf("RDS instance '%s' must have storage_encrypted = true", [resource_name])
}

# Deny EBS volumes without encryption
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_ebs_volume"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    not resource.change.after.encrypted
    message := sprintf("EBS volume '%s' must have encrypted = true", [resource_name])
}

# Deny launch templates with unencrypted EBS volumes
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_launch_template"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    some block in object.get(resource.change.after, "block_device_mappings", [])
    not object.get(block.ebs, "encrypted", false)
    message := sprintf("Launch template '%s' must have encrypted EBS volumes", [resource_name])
}

# Warn if S3 bucket doesn't have encryption configuration
warn[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_s3_bucket"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    # Check if there's a corresponding encryption configuration
    bucket_name := resource_name
    encryption_exists[input.planned_values.root_module.resources[_].address]
    not encryption_exists[bucket_name]
    message := sprintf("S3 bucket '%s' should have server-side encryption configured", [resource_name])
}
