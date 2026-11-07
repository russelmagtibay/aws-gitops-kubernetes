variable "project_name" {
  description = "Project identifier for naming and tagging AWS resources"
  type        = string
  default     = "aws-gitops-eks"
}

variable "environment" {
  description = "Target deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS Region (Singapore)"
  type        = string
  default     = "ap-southeast-1"
}

variable "az_subnet_map" {
  description = "Deterministic mapping of Availability Zones to Public and Private Subnet CIDRs"
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
  default = {
    "ap-southeast-1a" = {
      public_cidr  = "10.0.1.0/24"
      private_cidr = "10.0.11.0/24"
    }
    "ap-southeast-1b" = {
      public_cidr  = "10.0.2.0/24"
      private_cidr = "10.0.12.0/24"
    }
  }
}
