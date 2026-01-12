# =============================================================================
# OPA Policy: Restrict EC2 Instance Types by Environment
# =============================================================================
# This policy restricts EC2 instances to approved types based on environment.

package terraform.instances

# Approved instance types by environment
approved_types := {
    "dev": {"t3.nano", "t3.micro", "t3.small", "t2.nano", "t2.micro", "t2.small"},
    "staging": {"t3.small", "t3.medium", "t2.small", "t2.medium"},
    "prod": {"t3.medium", "t3.large", "t3.xlarge", "m5.large", "m5.xlarge", "m6i.large", "m6i.xlarge", "c5.large", "c5.xlarge", "r5.large", "r5.xlarge", "r6g.large"}
}

# Get environment from variables, default to "dev"
environment := object.get(input.variables, "environment", ["dev"])[0]

# Deny if instance type is not approved for the environment
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_instance"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    instance_type := resource.change.after.instance_type
    not instance_type in approved_types[environment]
    message := sprintf("EC2 instance '%s' uses type '%s' which is not approved for environment '%s'. Approved types: %v", [
        resource_name,
        instance_type,
        environment,
        approved_types[environment]
    ])
}

# Also check launch templates
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_launch_template"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    instance_type := resource.change.after.instance_type
    not instance_type in approved_types[environment]
    message := sprintf("Launch template '%s' uses instance type '%s' which is not approved for environment '%s'. Approved types: %v", [
        resource_name,
        instance_type,
        environment,
        approved_types[environment]
    ])
}
