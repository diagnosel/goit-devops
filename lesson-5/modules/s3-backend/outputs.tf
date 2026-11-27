output "bucket_url" {
  description = "S3 URL of the state bucket."
  value       = "s3://${aws_s3_bucket.state.bucket}"
}

output "table_name" {
  description = "Name of the DynamoDB lock table."
  value       = aws_dynamodb_table.locks.name
}
