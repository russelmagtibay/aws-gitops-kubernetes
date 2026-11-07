variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
  default     = ""
}

