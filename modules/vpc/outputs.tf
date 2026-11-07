output "vpc_id" {
  description = "ID of the provisioned EKS VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the EKS VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets (tagged with kubernetes.io/role/elb = 1)"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets (tagged with kubernetes.io/role/internal-elb = 1)"
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnets" {
  description = "Map of Availability Zone to public subnet object"
  value       = aws_subnet.public
}

output "private_subnets" {
  description = "Map of Availability Zone to private subnet object"
  value       = aws_subnet.private
}

output "s3_vpc_endpoint_id" {
  description = "ID of the free S3 Gateway VPC Endpoint for ECR layer pulls"
  value       = aws_vpc_endpoint.s3.id
}

output "nat_gateway_id" {
  description = "ID of the single NAT Gateway in ap-southeast-1a"
  value       = aws_nat_gateway.this.id
}
