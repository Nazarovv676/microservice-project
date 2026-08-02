output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state"
  value       = module.s3_backend.bucket_name
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket holding Terraform state"
  value       = module.s3_backend.bucket_arn
}

output "state_lock_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = module.s3_backend.lock_table_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the Django image"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository for the Django image"
  value       = module.ecr.repository_arn
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (для IRSA-ролей у lesson-8-9)"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_host" {
  description = "OIDC issuer host без схеми https://"
  value       = module.eks.oidc_provider_host
}

output "configure_kubectl" {
  description = "Команда для налаштування kubectl-доступу до кластера"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
