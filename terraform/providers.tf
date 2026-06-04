provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 5.0"
    }
  }

  # Backend configuration commented out — re-enable and update if you use remote state
  # backend "s3" {
  #   bucket = "common-bucket-name-test"
  #   key    = "common-terraform.tfstate"
  #   region = "us-east-1"
  # }
}