variable "bucket_name" {
  description = "Bucket Name"
  type = string
  default = "test-bucket-name-ck"
}

variable "environment" {
  description = "Enter environment"
  type = string
  default = "dev"
}

variable "region" {
  description = "Set the region"
  type = string
  default = "us-east-1"
}