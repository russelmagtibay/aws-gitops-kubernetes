locals {
  cluster_name = "${var.project_name}-${var.environment}-cluster"
}

# ============================================================================
# [AGK-1] Multi-AZ EKS Networking & Subnets
# ============================================================================
module "vpc" {
  source = "../../modules/vpc"

  project_name  = var.project_name
  environment   = var.environment
  aws_region    = var.aws_region
  cluster_name  = local.cluster_name
  az_subnet_map = var.az_subnet_map
}

# ============================================================================
# [AGK-7] Hardened Amazon ECR Container Registries (KMS + ScanOnPush + Lifecycle)
# ============================================================================
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ============================================================================
# [AGK-2 & AGK-7] FinOps Persistence, 3-Tier Zero-Trust IAM & GitHub OIDC Role
# ============================================================================
module "dynamodb" {
  source = "../../modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
}

module "sns" {
  source = "../../modules/sns"

  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source = "../../modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  dynamodb_table_arn  = module.dynamodb.table_arn
  sns_topic_arn       = module.sns.topic_arn
  ecr_repository_arns = module.ecr.repository_arns
}

# ============================================================================
# [AGK-3] Production Amazon EKS Control Plane & Compute
# ============================================================================
module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = local.cluster_name
  kubernetes_version = "1.31"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
}

# ============================================================================
# [AGK-5] EKS Pod Identity Association for 3-Tier Backend Workload
# ============================================================================
resource "aws_eks_pod_identity_association" "backend" {
  cluster_name    = module.eks.cluster_name
  namespace       = "production"
  service_account = "backend-sa"
  role_arn        = module.iam.backend_pod_role_arn

  depends_on = [
    module.eks
  ]
}
