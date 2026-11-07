variable "cluster_name" {
  description = "Name of the Amazon EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster and subnets reside"
  type        = string
}

variable "aws_region" {
  description = "AWS Region for Application Load Balancer provisioning"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "IAM Role ARN for the AWS Load Balancer Controller"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller"
  type        = string
  default     = "1.11.0"
}

