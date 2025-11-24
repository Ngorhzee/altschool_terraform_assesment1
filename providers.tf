provider "aws" {
  # Configuration options
  region = "us-east-1"
}

terraform {
  required_version = "1.13.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}