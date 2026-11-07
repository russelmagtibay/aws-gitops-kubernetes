output "vpc_id" {
  description = "EKS VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs for Internet-Facing AWS ALB"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs for EKS Managed Node Group"
  value       = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "Amazon EKS Cluster Name"
  value       = local.cluster_name
}

output "s3_vpc_endpoint_id" {
  description = "ID of the free S3 Gateway VPC Endpoint for ECR layer pulls"
  value       = module.vpc.s3_vpc_endpoint_id
}

output "nat_gateway_id" {
  description = "ID of the single NAT Gateway in ap-southeast-1a"
  value       = module.vpc.nat_gateway_id
}

# ============================================================================
# [AGK-2] IAM & Persistence Outputs
# ============================================================================
output "eks_cluster_role_arn" {
  description = "ARN of the EKS Cluster Control Plane IAM Role"
  value       = module.iam.cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS Managed Node Group IAM Role (Zero-SSH SSM enabled)"
  value       = module.iam.node_role_arn
}

output "backend_pod_role_arn" {
  description = "ARN of the Backend Microservice Pod IAM Role (EKS Pod Identity)"
  value       = module.iam.backend_pod_role_arn
}

output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM Role"
  value       = module.iam.alb_controller_role_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB Leads Table"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB Leads Table"
  value       = module.dynamodb.table_arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS Alerts Topic"
  value       = module.sns.topic_arn
}

# ============================================================================
# [AGK-3] EKS Cluster Outputs
# ============================================================================
output "cluster_endpoint" {
  description = "Endpoint for EKS Control Plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "node_group_arn" {
  description = "ARN of the EKS Managed Node Group"
  value       = module.eks.node_group_arn
}

# ============================================================================
# [AGK-4] AWS Load Balancer Controller Outputs
# ============================================================================
output "alb_controller_release_name" {
  description = "Helm release name for the AWS Load Balancer Controller"
  value       = module.alb_controller.release_name
}

output "alb_controller_release_version" {
  description = "Helm release version for the AWS Load Balancer Controller"
  value       = module.alb_controller.release_version
}

# ============================================================================
# [AGK-7] Amazon ECR & GitHub Actions OIDC Outputs
# ============================================================================
output "ecr_repository_urls" {
  description = "Map of Amazon ECR repository names to registry URLs"
  value       = module.ecr.repository_urls
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC IAM Role (github-actions-eks-gitops-role)"
  value       = module.iam.github_actions_role_arn
}
