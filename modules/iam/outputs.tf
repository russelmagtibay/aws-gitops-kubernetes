output "cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM Role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS Cluster IAM Role"
  value       = aws_iam_role.cluster.name
}

output "node_role_arn" {
  description = "ARN of the EKS Managed Node Group IAM Role"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the EKS Managed Node Group IAM Role"
  value       = aws_iam_role.node.name
}

output "backend_pod_role_arn" {
  description = "ARN of the Backend Pod IAM Role (EKS Pod Identity)"
  value       = aws_iam_role.backend_pod.arn
}

output "backend_pod_role_name" {
  description = "Name of the Backend Pod IAM Role"
  value       = aws_iam_role.backend_pod.name
}

output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM Role"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_role_name" {
  description = "Name of the AWS Load Balancer Controller IAM Role"
  value       = aws_iam_role.alb_controller.name
}


output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC IAM Role"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions OIDC IAM Role"
  value       = aws_iam_role.github_actions.name
}
