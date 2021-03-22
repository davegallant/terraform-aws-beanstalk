terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.15.0"
    }
  }
  backend "s3" {}
  required_version = "~> 0.14"
}
