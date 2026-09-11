terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.63"
    }
  }
  required_version = ">= 1.10"
}
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "retail-store"
      ManagedBy   = "terraform"
      Environment = var.environment_name
    }
  }
}
