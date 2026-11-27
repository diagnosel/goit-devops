output "state_bucket_url" {
  description = "S3 URL of the Terraform state bucket."
  value       = module.s3_backend.bucket_url
}

output "lock_table_name" {
  description = "DynamoDB table used for state locking."
  value       = module.s3_backend.table_name
}

output "vpc_id" {
  description = "ID of the lab VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs in availability zone order."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs in availability zone order."
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "URL used to push and pull lab Docker images."
  value       = module.ecr.repository_url
}
