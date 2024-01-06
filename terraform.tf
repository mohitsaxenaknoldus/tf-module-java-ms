terraform {
  cloud {
    organization = "ms-personal"

    workspaces {
      tags = ["javams"]
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.0"
    }
  }
}
