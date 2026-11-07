variable "project_name" {
  description = "Name of the project used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Amazon EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Standard support Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster is provisioned"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes and cluster ENIs"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM Role ARN for the EKS Cluster Control Plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM Role ARN for the EKS Managed Node Group"
  type        = string
}

variable "admin_principal_arn" {
  description = "IAM Principal ARN to grant cluster-admin access entry"
  type        = string
  default     = ""
}

variable "node_instance_types" {
  description = "EC2 instance types for the Managed Node Group (Free Tier eligible t3.small)"
  type        = list(string)
  default     = ["t3.small"]
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes (FinOps hard cap)"
  type        = number
  default     = 4
}

