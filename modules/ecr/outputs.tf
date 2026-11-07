output "repository_urls" {
  description = "Map of ECR repository names to their registry URLs"
  value       = { for k, repo in aws_ecr_repository.this : k => repo.repository_url }
}

output "repository_arns" {
  description = "List of Amazon ECR repository ARNs for least-privilege IAM scoping"
  value       = [for repo in aws_ecr_repository.this : repo.arn]
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting ECR repositories"
  value       = aws_kms_key.ecr.arn
}

