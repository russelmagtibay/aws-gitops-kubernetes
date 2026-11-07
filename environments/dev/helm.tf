# ============================================================================
# [AGK-4] AWS Load Balancer Controller via Helm
# ============================================================================
module "alb_controller" {
  source = "../../modules/alb_controller"

  cluster_name            = module.eks.cluster_name
  vpc_id                  = module.vpc.vpc_id
  aws_region              = var.aws_region
  alb_controller_role_arn = module.iam.alb_controller_role_arn

  depends_on = [
    module.eks
  ]
}

