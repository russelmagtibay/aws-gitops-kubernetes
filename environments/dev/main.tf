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
