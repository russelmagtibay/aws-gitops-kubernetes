variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for VPC endpoints and networking resources"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Amazon EKS cluster (required for Kubernetes subnet auto-discovery tags)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The vpc_cidr value must be a valid IPv4 CIDR block."
  }
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

  validation {
    condition     = length(var.az_subnet_map) >= 2
    error_message = "At least two Availability Zones must be mapped to ensure High Availability for Amazon EKS and AWS ALB."
  }

  validation {
    condition     = alltrue([for az in keys(var.az_subnet_map) : can(regex("^ap-southeast-1[a-c]$", az))])
    error_message = "All Availability Zone keys in az_subnet_map must be valid ap-southeast-1 AZ identifiers (ap-southeast-1a, ap-southeast-1b, ap-southeast-1c)."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.az_subnet_map) :
      can(cidrnetmask(subnet.public_cidr)) && can(cidrnetmask(subnet.private_cidr))
    ])
    error_message = "All public and private subnet CIDR blocks in az_subnet_map must be valid IPv4 CIDR notation."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.az_subnet_map) :
      subnet.public_cidr != subnet.private_cidr
    ])
    error_message = "Public CIDR and Private CIDR for the same Availability Zone cannot be identical."
  }
}

variable "nat_gateway_az" {
  description = "Availability Zone in which to place the single FinOps-optimized NAT Gateway"
  type        = string
  default     = "ap-southeast-1a"

  validation {
    condition     = can(regex("^ap-southeast-1[a-c]$", var.nat_gateway_az))
    error_message = "The nat_gateway_az value must be a valid ap-southeast-1 AZ identifier."
  }
}
