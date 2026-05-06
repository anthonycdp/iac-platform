package trivy

default ignore = false

ignore {
	input.Type == "misconfiguration"
	input.ID == "AWS-0053"
	input.CauseMetadata.Resource == "module.compute"
	resource_line_contains("resource \"aws_lb\" \"main\"")
}

ignore {
	input.Type == "misconfiguration"
	input.ID == "AWS-0054"
	input.CauseMetadata.Resource == "module.compute"
	resource_line_contains("resource \"aws_lb_listener\" \"http\"")
}

ignore {
	input.Type == "misconfiguration"
	input.ID == "AWS-0132"
	input.CauseMetadata.Resource == "module.storage"
	resource_line_contains("resource \"aws_s3_bucket_server_side_encryption_configuration\" \"logs\"")
}

ignore {
	input.Type == "misconfiguration"
	input.ID == "AWS-0132"
	input.CauseMetadata.Resource == "module.storage"
	resource_line_contains("resource \"aws_s3_bucket_server_side_encryption_configuration\" \"alb_logs\"")
}

ignore {
	input.Type == "misconfiguration"
	input.ID == "AWS-0132"
	input.CauseMetadata.Resource == "aws_s3_bucket_server_side_encryption_configuration.terraform_state_logs"
	resource_line_contains("resource \"aws_s3_bucket_server_side_encryption_configuration\" \"terraform_state_logs\"")
}

resource_line_contains(fragment) {
	some i
	contains(input.CauseMetadata.Code.Lines[i].Content, fragment)
}
