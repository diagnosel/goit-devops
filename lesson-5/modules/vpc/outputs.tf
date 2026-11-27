output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs in availability zone order."
  value       = [for zone in var.availability_zones : aws_subnet.public[zone].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs in availability zone order."
  value       = [for zone in var.availability_zones : aws_subnet.private[zone].id]
}
