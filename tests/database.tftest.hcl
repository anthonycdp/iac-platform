# =============================================================================
# Terraform Test: Database Module
# =============================================================================
# Tests for the database module to validate RDS configuration.

mock_provider "aws" {}

run "database_creation_test" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    name_prefix       = "test"
    environment       = "test"
    subnet_ids        = ["subnet-1", "subnet-2"]
    security_group_id = "sg-12345"
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    engine            = "postgres"
    engine_version    = "15.4"
    instance_class    = "db.t3.micro"
    database_name     = "testdb"
    username          = "dbadmin"
    allocated_storage = 20
    multi_az          = false
    tags = {
      Environment = "test"
    }
  }

  # Verify RDS instance is not publicly accessible
  assert {
    condition     = aws_db_instance.main.publicly_accessible == false
    error_message = "RDS instance should not be publicly accessible"
  }

  # Verify storage is encrypted
  assert {
    condition     = aws_db_instance.main.storage_encrypted == true
    error_message = "RDS storage should be encrypted"
  }

  # Verify deletion protection for non-prod
  assert {
    condition     = aws_db_instance.main.deletion_protection == false
    error_message = "Deletion protection should be disabled for non-prod environments"
  }

  # Verify skip final snapshot for non-prod
  assert {
    condition     = aws_db_instance.main.skip_final_snapshot == true
    error_message = "Skip final snapshot should be true for non-prod environments"
  }
}

run "database_prod_test" {
  command = plan

  module {
    source = "./modules/database"
  }

  variables {
    name_prefix       = "test"
    environment       = "prod"
    subnet_ids        = ["subnet-1", "subnet-2"]
    security_group_id = "sg-12345"
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    engine            = "postgres"
    engine_version    = "15.4"
    instance_class    = "db.t3.medium"
    database_name     = "testdb"
    username          = "dbadmin"
    allocated_storage = 100
    multi_az          = true
    tags = {
      Environment = "prod"
    }
  }

  # Verify deletion protection for prod
  assert {
    condition     = aws_db_instance.main.deletion_protection == true
    error_message = "Deletion protection should be enabled for prod environments"
  }

  # Verify Multi-AZ for prod
  assert {
    condition     = aws_db_instance.main.multi_az == true
    error_message = "Multi-AZ should be enabled for prod environments"
  }

  # Verify final snapshot identifier for prod
  assert {
    condition     = aws_db_instance.main.skip_final_snapshot == false
    error_message = "Skip final snapshot should be false for prod environments"
  }
}
