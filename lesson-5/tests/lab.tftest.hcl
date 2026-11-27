mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

run "state_storage_is_private_versioned_and_lockable" {
  command = apply

  module {
    source = "./modules/s3-backend"
  }

  variables {
    bucket_name = "example-lesson-5-test-state"
    table_name  = "terraform-locks"
  }

  assert {
    condition = (
      aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled" &&
      aws_s3_bucket_public_access_block.state.block_public_acls &&
      aws_s3_bucket_public_access_block.state.block_public_policy &&
      aws_s3_bucket_public_access_block.state.ignore_public_acls &&
      aws_s3_bucket_public_access_block.state.restrict_public_buckets &&
      one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    )
    error_message = "State storage must keep versions, block public access and use encryption."
  }

  assert {
    condition = (
      aws_dynamodb_table.locks.hash_key == "LockID" &&
      one(aws_dynamodb_table.locks.attribute).type == "S" &&
      jsondecode(aws_s3_bucket_policy.state.policy).Statement[0].Effect == "Deny" &&
      jsondecode(aws_s3_bucket_policy.state.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false"
    )
    error_message = "The backend needs a String LockID key and a policy that rejects HTTP."
  }
}

run "private_subnets_use_nat_and_public_subnets_use_igw" {
  command = apply

  module {
    source = "./modules/vpc"
  }

  variables {
    vpc_cidr_block     = "10.0.0.0/16"
    public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
    vpc_name           = "lesson-5-test"
  }

  assert {
    condition = (
      length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3 &&
      alltrue([for subnet in aws_subnet.private : !subnet.map_public_ip_on_launch]) &&
      aws_route.public_internet.gateway_id == aws_internet_gateway.this.id &&
      aws_route.private_internet.nat_gateway_id == aws_nat_gateway.this.id &&
      aws_nat_gateway.this.subnet_id == aws_subnet.public["us-west-2a"].id
    )
    error_message = "Create 3 subnet pairs; route public traffic through IGW and private traffic through NAT."
  }

  assert {
    condition = (
      alltrue([for link in aws_route_table_association.public : link.route_table_id == aws_route_table.public.id]) &&
      alltrue([for link in aws_route_table_association.private : link.route_table_id == aws_route_table.private.id]) &&
      length(aws_route_table_association.public) == 3 && length(aws_route_table_association.private) == 3
    )
    error_message = "Every subnet must use the route table for its public or private group."
  }
}

run "duplicate_availability_zones_are_rejected" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    vpc_cidr_block     = "10.0.0.0/16"
    public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    availability_zones = ["us-west-2a", "us-west-2a", "us-west-2c"]
    vpc_name           = "lesson-5-test"
  }

  expect_failures = [var.availability_zones]
}

run "ecr_scans_images_and_limits_access_to_the_lab_account" {
  command = apply

  module {
    source = "./modules/ecr"
  }

  variables {
    ecr_name     = "lesson-5-test"
    scan_on_push = true
  }

  assert {
    condition = (
      aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push &&
      aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE" &&
      jsondecode(aws_ecr_repository_policy.this.policy).Statement[0].Principal.AWS == "arn:aws:iam::123456789012:root" &&
      alltrue([for action in [
        "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage"
      ] : contains(jsondecode(aws_ecr_repository_policy.this.policy).Statement[0].Action, action)]) &&
      !contains(jsondecode(aws_ecr_repository_policy.this.policy).Statement[0].Action, "ecr:DeleteRepository") &&
      !contains(jsondecode(aws_ecr_repository_policy.this.policy).Statement[0].Action, "ecr:*")
    )
    error_message = "ECR must scan images and use the expected account in its push/pull policy."
  }
}

run "root_connects_all_three_modules" {
  command = apply

  variables {
    aws_account_id    = "123456789012"
    state_bucket_name = "example-lesson-5-test-state"
  }

  assert {
    condition = (
      output.state_bucket_url == "s3://example-lesson-5-test-state" &&
      output.lock_table_name == "terraform-locks" &&
      length(output.public_subnet_ids) == 3 && length(output.private_subnet_ids) == 3 &&
      length(output.ecr_repository_url) > 0
    )
    error_message = "Root outputs must expose the backend, six subnets and ECR URL."
  }
}
