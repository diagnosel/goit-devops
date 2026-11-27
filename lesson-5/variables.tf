variable "aws_account_id" {
  description = "Expected personal or course AWS account ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Use a 12-digit AWS account ID."
  }
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for this lab only."
  type        = string
}
