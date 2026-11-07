terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Reuses the existing hardened S3 state bucket with an isolated state key for Project #3
  backend "s3" {
    bucket       = "aws-gitops-platform-tfstate-570515227299"
    key          = "eks-gitops-platform/dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      JiraProject = "AGK"
      Owner       = "John Russel Magtibay"
    }
  }
}
