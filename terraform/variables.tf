variable "region" {
  description = "The AWS region where the resources will be created"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "The environment for the resources (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
