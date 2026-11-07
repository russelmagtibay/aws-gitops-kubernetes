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
