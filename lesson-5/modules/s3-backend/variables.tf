variable "bucket_name" {
  description = "Globally unique name of the lab state bucket."
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB lock table."
  type        = string
}
