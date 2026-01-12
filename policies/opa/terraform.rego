# =============================================================================
# OPA Policy: Terraform Security and Compliance
# =============================================================================
# This policy enforces security and compliance rules on Terraform plans.

package terraform.analysis

import input as tfplan

########################
# Parameters for Policy
########################

# Maximum acceptable score for automated authorization (blast radius)
blast_radius := 30

# Weights assigned for each operation on each resource-type
weights := {
    "aws_autoscaling_group": {"delete": 100, "create": 10, "modify": 1},
    "aws_instance": {"delete": 10, "create": 1, "modify": 1},
    "aws_db_instance": {"delete": 100, "create": 10, "modify": 5},
    "aws_lb": {"delete": 50, "create": 5, "modify": 2},
    "aws_s3_bucket": {"delete": 50, "create": 5, "modify": 2},
}

# Resource types to consider in calculations
resource_types := {"aws_autoscaling_group", "aws_instance", "aws_db_instance", "aws_lb", "aws_s3_bucket", "aws_iam", "aws_iam_role", "aws_iam_policy"}

#########
# Policy
#########

# Authorization holds if score for the plan is acceptable and no changes to IAM
default authz := false

authz if {
    score < blast_radius
    not touches_iam
    no_public_s3_buckets
    encryption_enabled
}

# Compute the score for a Terraform plan
score := s if {
    all_resources := [x |
        some resource_type, crud in weights
        del := crud.delete * num_deletes[resource_type]
        new := crud.create * num_creates[resource_type]
        mod := crud.modify * num_modifies[resource_type]
        x := (del + new) + mod
    ]
    s := sum(all_resources)
}

# Check if there are any changes to IAM
touches_iam if {
    count(iam_resources) > 0
}

iam_resources[resource_type] := all_resources if {
    some resource_type in ["aws_iam", "aws_iam_role", "aws_iam_policy"]
    all_resources := [name |
        some name in tfplan.resource_changes
        name.type == resource_type
    ]
    count(all_resources) > 0
}

# Check for public S3 buckets
no_public_s3_buckets if {
    every bucket in s3_buckets {
        not bucket_is_public(bucket)
    }
}

bucket_is_public(bucket) {
    some change in bucket.change.after
    change.public == true
}

s3_buckets[bucket] {
    some bucket in tfplan.resource_changes
    bucket.type == "aws_s3_bucket"
}

# Check encryption is enabled
encryption_enabled if {
    every resource in encrypted_resources {
        resource_has_encryption(resource)
    }
}

resource_has_encryption(resource) {
    some change in resource.change.after
    change.encryption_enabled == true
}

encrypted_resources[resource] {
    some resource in tfplan.resource_changes
    resource.type in ["aws_db_instance", "aws_ebs_volume", "aws_s3_bucket"]
}

####################
# Terraform Library
####################

# List of all resources of a given type
resources[resource_type] := all_resources if {
    some resource_type in resource_types
    all_resources := [name |
        some name in tfplan.resource_changes
        name.type == resource_type
    ]
}

# Number of creations of resources of a given type
num_creates[resource_type] := num if {
    some resource_type in resource_types
    all_resources := resources[resource_type]
    creates := [res |
        some res in all_resources
        "create" in res.change.actions
    ]
    num := count(creates)
}

# Number of deletions of resources of a given type
num_deletes[resource_type] := num if {
    some resource_type in resource_types
    all_resources := resources[resource_type]
    deletions := [res |
        some res in all_resources
        "delete" in res.change.actions
    ]
    num := count(deletions)
}

# Number of modifications to resources of a given type
num_modifies[resource_type] := num if {
    some resource_type in resource_types
    all_resources := resources[resource_type]
    modifies := [res |
        some res in all_resources
        "update" in res.change.actions
    ]
    num := count(modifies)
}
