# =============================================================================
# OPA Policy: Require Tags on All Resources
# =============================================================================
# This Rego policy validates that all AWS resources have required tags.
# Use with Terraform via conftest or the OPA Terraform provider.

package terraform.tags

# Required tags that must be present on all resources
required_tags := {"Environment", "ManagedBy", "Project"}

# Deny resources that are missing required tags
deny[message] {
    some resource_type, resource_name, resource in input.resource_changes
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    object.get(resource.change.after, "tags", null)
    missing := required_tags - {tag | some tag; resource.change.after.tags[tag]}
    count(missing) > 0
    message := sprintf("Resource %s (%s) is missing required tags: %v", [
        resource_name,
        resource_type,
        missing
    ])
}

# Warn if tags don't follow naming conventions
warn[message] {
    some resource_type, resource_name, resource in input.resource_changes
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    tags := object.get(resource.change.after, "tags", {})
    some tag_name in required_tags
    not tags[tag_name]
    message := sprintf("Resource %s should have tag '%s'", [
        resource_name,
        tag_name
    ])
}
