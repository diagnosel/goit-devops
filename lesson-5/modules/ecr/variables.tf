variable "ecr_name" {
  description = "Name of the private ECR repository."
  type        = string
}

variable "scan_on_push" {
  description = "Scan each image after it is pushed."
  type        = bool
  default     = true
}
