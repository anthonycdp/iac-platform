# =============================================================================
# OPA Policy: Prohibit Public S3 Buckets
# =============================================================================
# This policy prevents public access to S3 buckets.

package terraform.s3_public

# Deny S3 buckets with public ACLs
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_s3_bucket_acl"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    acl := resource.change.after.acl
    acl in {"public-read", "public-read-write", "authenticated-read"}
    message := sprintf("S3 bucket ACL '%s' grants public access with ACL '%s'", [resource_name, acl])
}

# Deny if public access block doesn't block all public access
deny[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_s3_bucket_public_access_block"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    config := resource.change.after
    not (config.block_public_acls == true &&
         config.block_public_policy == true &&
         config.ignore_public_acls == true &&
         config.restrict_public_buckets == true)
    message := sprintf("S3 bucket public access block '%s' must block all public access. Current: block_public_acls=%v, block_public_policy=%v, ignore_public_acls=%v, restrict_public_buckets=%v", [
        resource_name,
        config.block_public_acls,
        config.block_public_policy,
        config.ignore_public_acls,
        config.restrict_public_buckets
    ])
}

# Warn if bucket doesn't have public access block
warn[message] {
    some _, resource_name, resource in input.resource_changes
    resource.type == "aws_s3_bucket"
    resource.mode == "managed"
    resource.change.actions[_] != "delete"
    # This is a warning because we can't easily check if a public access block exists
    message := sprintf("S3 bucket '%s' should have a public_access_block resource", [resource_name])
}
