variable "vpc_cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "Three public CIDR blocks in availability zone order."
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == 3
    error_message = "Provide exactly three public subnet CIDR blocks."
  }
}

variable "private_subnets" {
  description = "Three private CIDR blocks in availability zone order."
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) == 3
    error_message = "Provide exactly three private subnet CIDR blocks."
  }
}

variable "availability_zones" {
  description = "Three different availability zones for the subnet pairs."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3 && length(toset(var.availability_zones)) == 3
    error_message = "Provide exactly three different availability zones."
  }
}

variable "vpc_name" {
  description = "Name prefix for lab network resources."
  type        = string
}
