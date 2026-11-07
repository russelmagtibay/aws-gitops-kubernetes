variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "repository_names" {
  description = "Set of Amazon ECR repository names to provision"
  type        = set(string)
  default = [
    "lead-capture-backend",
    "lead-capture-frontend"
  ]

  validation {
    condition     = length(var.repository_names) >= 1
    error_message = "At least one ECR repository name must be specified."
  }
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (IMMUTABLE for Checkov CKV_AWS_51)"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "max_image_count" {
  description = "Maximum number of container images to retain per repository (FinOps lifecycle control)"
  type        = number
  default     = 5
}

