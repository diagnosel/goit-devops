output "repository_url" {
  description = "Private ECR repository URL."
  value       = aws_ecr_repository.this.repository_url
}
