output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group managed by EKS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  description = "ARN of the IAM role used by worker nodes"
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (для IRSA-ролей інших модулів, напр. Jenkins/Kaniko)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_host" {
  description = "OIDC issuer host без схеми https:// (для умов sub/aud у trust policy IRSA-ролей)"
  value       = local.oidc_provider_host
}
