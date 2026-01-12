# Policy-as-Code

This directory contains policy-as-code implementations using both Sentinel and OPA.

## Sentinel Policies

Sentinel is HashiCorp's policy-as-code framework used with Terraform Cloud/Enterprise.

### Available Policies

| Policy | Description |
|--------|-------------|
| `require_tags.sentinel` | Ensures all resources have required tags |
| `restrict_instance_types.sentinel` | Limits EC2 instance types by environment |
| `require_encryption.sentinel` | Requires encryption for storage resources |
| `prohibit_public_s3.sentinel` | Prevents public S3 bucket access |

### Usage with Terraform Cloud

1. Navigate to your organization's policy sets
2. Create a new policy set pointing to this repository
3. Configure the policies to run on your workspaces

## OPA Policies

Open Policy Agent (OPA) policies can be used with `conftest` or other OPA integrators.

### Available Policies

| Policy | Description |
|--------|-------------|
| `require_tags.rego` | Validates required tags on resources |
| `restrict_instance_types.rego` | Validates instance types by environment |
| `require_encryption.rego` | Validates encryption is enabled |
| `prohibit_public_s3.rego` | Validates S3 buckets are not public |

### Usage with Conftest

```bash
# Generate a plan
cd environments/dev
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Run policy checks
conftest test tfplan.json \
  --policy ../../policies/opa \
  --all-namespaces

# With output
conftest test tfplan.json \
  --policy ../../policies/opa \
  --all-namespaces \
  --output table
```

### Usage in CI/CD

```yaml
- name: Run OPA Policy Checks
  run: |
    conftest test environments/dev/tfplan.json \
      --policy policies/opa \
      --all-namespaces
```

## Adding New Policies

### Sentinel

1. Create a new `.sentinel` file in `policies/sentinel/`
2. Follow the Sentinel language syntax
3. Test with `sentinel apply <policy.sentinel>`

### OPA

1. Create a new `.rego` file in `policies/opa/`
2. Use the `terraform` package namespace
3. Define `deny` rules for violations
4. Test with `conftest verify`
