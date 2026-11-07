variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB leads table for least-privilege pod access"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS alerts topic for least-privilege pod publishing"
  type        = string
}

variable "ecr_repository_arns" {
  description = "List of Amazon ECR repository ARNs for GitHub Actions OIDC push access"
  type        = list(string)
  default     = []
}

variable "github_repositories" {
  description = "GitHub repositories allowed to assume the GitHub Actions OIDC IAM Role"
  type        = list(string)
  default = [
    "russelmagtibay/aws-gitops-kubernetes",
    "rjcloudev/aws-gitops-kubernetes"
  ]
}
