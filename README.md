# Infrastructure as Code Platform

A production-ready Infrastructure as Code (IaC) project implementing multi-environment AWS infrastructure using Terraform. This project demonstrates best practices for infrastructure automation, including modular design, policy-as-code, state management, and CI/CD integration.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Module Documentation](#module-documentation)
- [Environment Configuration](#environment-configuration)
- [State Management](#state-management)
- [Governance & Policies](#governance--policies)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security](#security)
- [Cost Management](#cost-management)
- [Contributing](#contributing)

---

## Overview

This project provides a complete infrastructure platform that can be deployed across multiple environments (development, staging, production) with consistent, reproducible results. It follows the principle of "infrastructure as code" where all infrastructure components are defined, versioned, and managed through code.

### Key Principles

- **Modularity**: Reusable Terraform modules for each infrastructure component
- **Scalability**: Auto-scaling compute resources and read replicas for databases
- **Security**: Encryption at rest, network isolation, WAF protection
- **Observability**: Comprehensive monitoring, logging, and alerting
- **Governance**: Policy-as-code for compliance and cost control

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                              VPC (10.x.0.0/16)                         │  │
│  │                                                                        │  │
│  │   ┌────────────────────────────────────────────────────────────────┐  │  │
│  │   │                    Public Subnets (AZ-a, AZ-b, AZ-c)           │  │  │
│  │   │                                                                 │  │  │
│  │   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │  │
│  │   │   │     ALB     │    │     ALB     │    │     ALB     │       │  │  │
│  │   │   │   (Active)  │    │   (Active)  │    │   (Active)  │       │  │  │
│  │   │   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘       │  │  │
│  │   │          │                  │                  │               │  │  │
│  │   │   ┌──────┴──────────────────┴──────────────────┴──────┐       │  │  │
│  │   │   │                   Internet Gateway                │       │  │  │
│  │   │   └────────────────────────────────────────────────────┘       │  │  │
│  │   └────────────────────────────────────────────────────────────────┘  │  │
│  │                                    │                                   │  │
│  │                                    ▼                                   │  │
│  │   ┌────────────────────────────────────────────────────────────────┐  │  │
│  │   │                   Private Subnets (AZ-a, AZ-b, AZ-c)           │  │  │
│  │   │                                                                 │  │  │
│  │   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │  │
│  │   │   │   EC2/ASG   │    │   EC2/ASG   │    │   EC2/ASG   │       │  │  │
│  │   │   │  Instance 1 │    │  Instance 2 │    │  Instance N │       │  │  │
│  │   │   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘       │  │  │
│  │   │          │                  │                  │               │  │  │
│  │   │          └──────────────────┼──────────────────┘               │  │  │
│  │   │                             │                                  │  │  │
│  │   │                    ┌────────┴────────┐                         │  │  │
│  │   │                    │   NAT Gateway   │                         │  │  │
│  │   │                    │  (Per AZ)       │                         │  │  │
│  │   │                    └─────────────────┘                         │  │  │
│  │   └────────────────────────────────────────────────────────────────┘  │  │
│  │                                    │                                   │  │
│  │                                    ▼                                   │  │
│  │   ┌────────────────────────────────────────────────────────────────┐  │  │
│  │   │                  Database Subnets (AZ-a, AZ-b, AZ-c)           │  │  │
│  │   │                                                                 │  │  │
│  │   │   ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │   │   │                    RDS PostgreSQL                        │  │  │  │
│  │   │   │              ┌───────────┬───────────┐                  │  │  │  │
│  │   │   │              │  Primary  │  Replica  │                  │  │  │  │
│  │   │   │              │  (AZ-a)   │  (AZ-b)   │                  │  │  │  │
│  │   │   │              └───────────┴───────────┘                  │  │  │  │
│  │   │   └─────────────────────────────────────────────────────────┘  │  │  │
│  │   └────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Shared Services                               │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │   │
│  │  │    S3       │  │ CloudWatch  │  │     WAF     │  │    KMS     │ │   │
│  │  │  (Storage)  │  │ (Monitoring)│  │  (Security) │  │ (Encrypt)  │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Network Architecture

```
                                    ┌─────────────┐
                                    │  Internet   │
                                    └──────┬──────┘
                                           │
                              ┌────────────┴────────────┐
                              │    Route 53 (DNS)       │
                              └────────────┬────────────┘
                                           │
                              ┌────────────┴────────────┐
                              │  CloudFront (CDN)       │
                              │  (Optional)             │
                              └────────────┬────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
            ┌───────┴───────┐      ┌───────┴───────┐      ┌───────┴───────┐
            │  Public Subnet │      │  Public Subnet │      │  Public Subnet │
            │   10.x.1.0/24  │      │   10.x.2.0/24  │      │   10.x.3.0/24  │
            │    (AZ-a)      │      │    (AZ-b)      │      │    (AZ-c)      │
            │  ┌───────────┐ │      │  ┌───────────┐ │      │  ┌───────────┐ │
            │  │    ALB    │ │      │  │    ALB    │ │      │  │    ALB    │ │
            │  └───────────┘ │      │  └───────────┘ │      │  └───────────┘ │
            └───────┬───────┘      └───────┬───────┘      └───────┬───────┘
                    │                      │                      │
                    └──────────────────────┼──────────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
            ┌───────┴───────┐      ┌───────┴───────┐      ┌───────┴───────┐
            │ Private Subnet │      │ Private Subnet │      │ Private Subnet │
            │  10.x.11.0/24  │      │  10.x.12.0/24  │      │  10.x.13.0/24  │
            │    (AZ-a)      │      │    (AZ-b)      │      │    (AZ-c)      │
            │  ┌───────────┐ │      │  ┌───────────┐ │      │  ┌───────────┐ │
            │  │    EC2    │ │      │  │    EC2    │ │      │  │    EC2    │ │
            │  │    ASG    │ │      │  │    ASG    │ │      │  │    ASG    │ │
            │  └───────────┘ │      │  └───────────┘ │      │  └───────────┘ │
            └───────┬───────┘      └───────┬───────┘      └───────┬───────┘
                    │                      │                      │
                    └──────────────────────┼──────────────────────┘
                                           │
            ┌──────────────────────────────┼──────────────────────┐
            │                      │                      │        │
    ┌───────┴───────┐      ┌───────┴───────┐      ┌───────┴───────┐│
    │  DB Subnet    │      │  DB Subnet    │      │  DB Subnet    ││
    │ 10.x.21.0/24  │      │ 10.x.22.0/24  │      │ 10.x.23.0/24  ││
    │   (AZ-a)      │      │   (AZ-b)      │      │   (AZ-c)      ││
    │ ┌───────────┐ │      │ ┌───────────┐ │      │               ││
    │ │   RDS     │ │      │ │   RDS     │ │      │               ││
    │ │  Primary  │ │      │ │  Replica  │ │      │               ││
    │ └───────────┘ │      │ └───────────┘ │      │               ││
    └───────────────┘      └───────────────┘      └───────────────┘│
    └─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
iac-platform/
├── modules/                      # Reusable Terraform modules
│   ├── networking/              # VPC, subnets, NAT gateways
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/                 # ALB, ASG, EC2 instances
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user_data.sh.tpl
│   ├── database/                # RDS PostgreSQL
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/                 # S3 buckets
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── monitoring/              # CloudWatch, SNS, alerts
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security/                # Security groups, KMS, WAF
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/                 # Environment-specific configs
│   ├── dev/                     # Development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/                 # Staging environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/                    # Production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── policies/                     # Policy-as-code
│   ├── sentinel/                # HashiCorp Sentinel policies
│   │   ├── require_tags.sentinel
│   │   ├── restrict_instance_types.sentinel
│   │   ├── require_encryption.sentinel
│   │   └── prohibit_public_s3.sentinel
│   └── opa/                     # Open Policy Agent policies
│       ├── require_tags.rego
│       ├── restrict_instance_types.rego
│       ├── require_encryption.rego
│       └── prohibit_public_s3.rego
│
├── state-management/            # Bootstrap state infrastructure
│   └── main.tf
│
├── scripts/                     # Utility scripts
│   └── validate.sh              # Validation script
│
├── .github/                     # GitHub Actions workflows
│   └── workflows/
│       ├── terraform.yml        # Terraform CI/CD
│       └── security-scan.yml    # Security scanning
│
├── versions.tf                  # Provider version constraints
├── providers.tf                 # Provider configuration
├── variables.tf                 # Global variables
├── outputs.tf                   # Global outputs
├── backend-config.tf            # Backend configuration template
└── README.md                    # This file
```

---

## Features

### Infrastructure Components

| Component | Features |
|-----------|----------|
| **Networking** | Multi-AZ VPC, Public/Private/Database subnets, NAT Gateways, VPC Flow Logs |
| **Compute** | Application Load Balancer, Auto Scaling Group, Launch Templates, Instance Refresh |
| **Database** | RDS PostgreSQL, Multi-AZ, Read Replicas, Automated Backups, Performance Insights |
| **Storage** | S3 Buckets with versioning, encryption, lifecycle policies, object lock |
| **Security** | Security Groups, KMS encryption, WAF, IAM roles, Secrets Manager |
| **Monitoring** | CloudWatch Logs/Metrics, Alarms, Dashboard, AWS Config, SNS notifications |

### Best Practices Implemented

- **Modular Design**: Reusable modules with clear interfaces
- **Remote State**: S3 backend with DynamoDB locking
- **Variable Validation**: Input validation for critical variables
- **Output Organization**: Structured outputs for cross-reference
- **Tag Strategy**: Consistent tagging across all resources
- **Encryption**: Default encryption at rest and in transit
- **Least Privilege**: Minimal IAM permissions
- **Cost Optimization**: Environment-specific sizing

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.6.0 | Infrastructure provisioning |
| AWS CLI | >= 2.0 | AWS interaction |
| conftest | latest | Policy testing (optional) |
| tfsec | latest | Security scanning (optional) |
| checkov | latest | IaC scanning (optional) |

### AWS Requirements

- AWS Account with appropriate permissions
- IAM User or Role with the following policies:
  - `AdministratorAccess` (for initial setup)
  - Or granular permissions for specific services
- S3 bucket for Terraform state (can be created via bootstrap)
- DynamoDB table for state locking

### Installation

```bash
# Install Terraform (macOS)
brew install terraform

# Install AWS CLI
brew install awscli

# Configure AWS credentials
aws configure

# Install optional tools
brew install conftest tfsec checkov
```

---

## Getting Started

### 1. Bootstrap State Management

First, create the S3 bucket and DynamoDB table for state storage:

```bash
cd state-management

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply to create state infrastructure
terraform apply

# Note the outputs for backend configuration
terraform output
```

### 2. Configure Backend

Update the backend configuration in each environment's `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### 3. Deploy Development Environment

```bash
cd environments/dev

# Initialize with backend
terraform init

# Review the plan
terraform plan -var-file=terraform.tfvars

# Apply the configuration
terraform apply -var-file=terraform.tfvars
```

### 4. Deploy to Other Environments

```bash
# Staging
cd environments/staging
terraform init
terraform apply -var-file=terraform.tfvars

# Production (requires approval)
cd environments/prod
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

---

## Module Documentation

### Networking Module

Creates a complete VPC networking infrastructure.

```hcl
module "networking" {
  source = "./modules/networking"

  name_prefix          = "myapp-dev"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Set false for prod
  enable_flow_logs   = true
}
```

### Compute Module

Creates ALB, ASG, and EC2 instances.

```hcl
module "compute" {
  source = "./modules/compute"

  name_prefix        = "myapp-dev"
  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.compute_security_group_id

  instance_type       = "t3.micro"
  asg_min_size        = 1
  asg_max_size        = 3
  asg_desired_capacity = 2
}
```

### Database Module

Creates RDS PostgreSQL with encryption and backups.

```hcl
module "database" {
  source = "./modules/database"

  name_prefix       = "myapp-dev"
  environment       = "dev"
  subnet_ids        = module.networking.database_subnet_ids
  security_group_id = module.security.database_security_group_id
  kms_key_id        = module.security.kms_key_id

  engine            = "postgres"
  instance_class    = "db.t3.micro"
  database_name     = "myapp"
  multi_az          = false
  allocated_storage = 20
}
```

---

## Environment Configuration

### Environment Comparison

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| **Instance Type** | t3.micro | t3.small | m6i.large |
| **ASG Size** | 1-2 | 2-4 | 3-10 |
| **Database** | db.t3.micro | db.t3.small | db.r6g.large |
| **Multi-AZ DB** | No | No | Yes |
| **Read Replica** | No | No | Yes |
| **NAT Gateway** | Single | Multi-AZ | Multi-AZ |
| **WAF** | No | Yes | Yes |
| **Backup Retention** | 1 day | 7 days | 30 days |
| **Log Retention** | 7 days | 30 days | 90 days |

### Environment-Specific Variables

Override default variables in each environment's `terraform.tfvars`:

```hcl
# environments/prod/terraform.tfvars
project_name   = "iac-platform"
environment    = "prod"
aws_region     = "us-east-1"

# Larger CIDR for production scale
vpc_cidr = "10.2.0.0/16"

# Restrict access
allowed_ssh_cidrs = ["10.0.0.0/8"]

# Production database
database_multi_az = true
database_instance_class = "db.r6g.large"

# Enhanced monitoring
alarm_email = "prod-oncall@example.com"
```

---

## State Management

### Backend Configuration

This project uses S3 for remote state storage with DynamoDB for locking:

```
┌─────────────────┐     ┌─────────────────┐
│   S3 Bucket     │     │   DynamoDB      │
│  (State Files)  │     │ (State Locking) │
│                 │     │                 │
│ dev/tfstate     │     │ LockID (PK)     │
│ staging/tfstate │     │                 │
│ prod/tfstate    │     │                 │
└─────────────────┘     └─────────────────┘
```

### State Commands

```bash
# View current state
terraform state list

# Show specific resource
terraform state show module.networking.aws_vpc.main

# Move resource (refactoring)
terraform state mv module.networking.aws_vpc.main module.networking.aws_vpc.this

# Import existing resource
terraform import aws_s3_bucket.existing existing-bucket-name

# Remove from state (doesn't delete resource)
terraform state rm aws_s3_bucket.deprecated
```

### Workspace Isolation

Each environment maintains separate state files:
- `environments/dev/terraform.tfstate`
- `environments/staging/terraform.tfstate`
- `environments/prod/terraform.tfstate`

---

## Terragrunt (Alternative)

This project supports Terragrunt for DRY multi-environment deployments.

### Terragrunt Commands

```bash
# Initialize Terragrunt for an environment
cd environments/dev
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Run all modules in an environment
terragrunt run-all plan
terragrunt run-all apply

# Using Makefile
make tg-init ENV=dev
make tg-plan ENV=dev
make tg-apply ENV=dev
make tg-run-all-apply ENV=dev
```

### Terragrunt Architecture

```
terragrunt.hcl (root)
├── environments/
│   ├── terragrunt.hcl (environment config)
│   ├── dev/
│   │   └── terragrunt.hcl
│   ├── staging/
│   │   └── terragrunt.hcl
│   └── prod/
│       └── terragrunt.hcl
└── modules/
    ├── networking/
    ├── compute/
    ├── database/
    ├── storage/
    ├── security/
    └── monitoring/
```

### Key Terragrunt Features

- **DRY**: Remote state configuration defined once at root
- **Auto-init**: Automatically runs terraform init when needed
- **Dependencies**: Manages module dependencies
- **Before/After Hooks**: Run commands before/after Terraform operations

---

## Governance & Policies

### Policy Framework

This project implements policy-as-code using both Sentinel and OPA:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Policy Enforcement                           │
│                                                                  │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐   │
│  │   Sentinel    │    │      OPA      │    │   AWS Config  │   │
│  │ (Terraform    │    │  (conftest)   │    │   (Runtime)   │   │
│  │   Cloud)      │    │               │    │               │   │
│  └───────────────┘    └───────────────┘    └───────────────┘   │
│                                                                  │
│  Policies:                                                       │
│  • Require tags on all resources                                │
│  • Restrict instance types by environment                        │
│  • Require encryption at rest                                   │
│  • Prohibit public S3 buckets                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Running Policy Checks

```bash
# Using conftest with OPA policies
cd environments/dev
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy ../../policies/opa --all-namespaces
```

### Policy Examples

**Require Tags (OPA/Rego):**
```rego
package terraform.tags

required_tags := {"Environment", "ManagedBy", "Project"}

deny[message] {
    some resource_type, resource_name, resource in input.resource_changes
    resource.mode == "managed"
    missing := required_tags - {tag | some tag; resource.change.after.tags[tag]}
    count(missing) > 0
    message := sprintf("Resource %s missing tags: %v", [resource_name, missing])
}
```

---

## CI/CD Pipeline

### Pipeline Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Commit    │────▶│  Validate   │────▶│  Security   │────▶│    Plan     │
│   /PR       │     │   Check     │     │    Scan     │     │   Review    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                    │
                                          ┌─────────────────────────┘
                                          ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Applied   │◀────│   Manual    │◀────│   Policy    │
│   (Auto)    │     │  Approval   │     │   Check     │
└─────────────┘     │   (Prod)    │     └─────────────┘
                    └─────────────┘
```

### Workflow Triggers

| Event | Actions |
|-------|---------|
| Pull Request | Validate, Format Check, Security Scan, Plan |
| Push to main | Apply to Dev (auto), Apply to Prod (manual) |
| Schedule | Daily security scans |

### Required Secrets

```yaml
# GitHub Repository Secrets
AWS_ACCESS_KEY_ID          # AWS access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
TF_STATE_BUCKET            # S3 bucket for state
TF_LOCK_TABLE              # DynamoDB table for locking
AWS_ACCESS_KEY_ID_PROD     # Production AWS credentials
AWS_SECRET_ACCESS_KEY_PROD # Production AWS credentials
```

---

## Security

### Security Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                     Security Architecture                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: Network Security                                      │
│  ├── VPC isolation                                              │
│  ├── Private subnets for compute and database                   │
│  ├── Security groups (stateful firewalls)                       │
│  └── Network ACLs (stateless firewalls)                         │
│                                                                  │
│  Layer 2: Access Control                                        │
│  ├── IAM roles with least privilege                             │
│  ├── Security group restrictions                                │
│  └── SSH access restricted to specific CIDRs                    │
│                                                                  │
│  Layer 3: Encryption                                            │
│  ├── KMS encryption for data at rest                            │
│  ├── TLS/HTTPS for data in transit                              │
│  └── Encrypted S3 buckets and RDS                               │
│                                                                  │
│  Layer 4: Application Security                                  │
│  ├── WAF for web application firewall                           │
│  ├── Rate limiting                                              │
│  └── Managed rule sets (SQL injection, XSS)                     │
│                                                                  │
│  Layer 5: Monitoring & Compliance                               │
│  ├── CloudWatch logs and metrics                                │
│  ├── AWS Config for compliance                                  │
│  └── Security Hub integration                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Security Best Practices

1. **Encryption**: All data encrypted at rest using KMS
2. **Network Isolation**: Database in private subnets
3. **Least Privilege**: Minimal IAM permissions
4. **Audit Logging**: CloudTrail and VPC Flow Logs
5. **Secret Management**: Secrets Manager for credentials
6. **Regular Patching**: Automated instance refresh

---

## Cost Management

### AWS Budgets

Budgets are configured for each environment:

| Environment | Monthly Budget | Alerts |
|-------------|----------------|--------|
| Dev | $50 | 80%, 100%, 120% |
| Staging | $200 | 80%, 100%, 120% |
| Prod | $500 | 80%, 100%, 120% |

### Cost Optimization Strategies

1. **Right-sizing**: Environment-appropriate instance types
2. **Single NAT Gateway**: Cost savings for non-prod
3. **Lifecycle Policies**: Move old data to Glacier
4. **Reserved Instances**: For production workloads
5. **Spot Instances**: For stateless, fault-tolerant workloads

### Cost Monitoring

```bash
# View daily costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost

# View costs by service
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --group-by Type=DIMENSION,Key=SERVICE \
  --metrics BlendedCost
```

---

## Contributing

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Make** your changes
4. **Run** validation script (`./scripts/validate.sh`)
5. **Commit** your changes (`git commit -m 'Add amazing feature'`)
6. **Push** to the branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Code Style

- Run `terraform fmt` before committing
- Run `terraform validate` to check syntax
- Add documentation for new modules
- Update README.md for significant changes

### Pre-commit Hooks

```bash
# Install pre-commit
brew install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

For questions or support, please open an issue in this repository.

---

*Built with Terraform | Designed for production workloads*
