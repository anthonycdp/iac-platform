# =============================================================================
# Terraform Test: Networking Module
# =============================================================================
# Tests for the networking module to validate VPC configuration.

mock_provider "aws" {}

run "vpc_creation_test" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    name_prefix           = "test"
    vpc_cidr              = "10.0.0.0/16"
    availability_zones    = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
    database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
    enable_nat_gateway    = false
    tags = {
      Environment = "test"
    }
  }

  # Verify VPC is created with correct CIDR
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block should be 10.0.0.0/16"
  }

  # Verify DNS support is enabled
  assert {
    condition     = aws_vpc.main.enable_dns_support == true
    error_message = "DNS support should be enabled"
  }

  # Verify DNS hostnames are enabled
  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled"
  }

  # Verify correct number of public subnets
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets"
  }

  # Verify correct number of private subnets
  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets"
  }

  # Verify correct number of database subnets
  assert {
    condition     = length(aws_subnet.database) == 2
    error_message = "Should create 2 database subnets"
  }

  # Verify public subnets have public IP on launch
  assert {
    condition     = aws_subnet.public[0].map_public_ip_on_launch == true
    error_message = "Public subnets should have auto-assign public IP enabled"
  }
}

run "nat_gateway_test" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    name_prefix           = "test"
    vpc_cidr              = "10.0.0.0/16"
    availability_zones    = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
    database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
    enable_nat_gateway    = true
    single_nat_gateway    = true
    tags = {
      Environment = "test"
    }
  }

  # Verify single NAT gateway is created when enabled
  assert {
    condition     = length(aws_nat_gateway.main) == 1
    error_message = "Should create 1 NAT gateway when single_nat_gateway is true"
  }
}
