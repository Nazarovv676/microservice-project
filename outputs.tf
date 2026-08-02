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
  description = "ARN of the cluster's IAM OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Команда для налаштування kubectl-доступу до кластера"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "jenkins_namespace" {
  description = "Namespace, у якому встановлено Jenkins"
  value       = module.jenkins.namespace
}

output "jenkins_url" {
  description = "Command to get Jenkins UI URL"
  value       = "kubectl -n ${module.jenkins.namespace} get svc ${module.jenkins.release_name} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "jenkins_get_admin_password" {
  description = "Command to retrieve the initial Jenkins admin password"
  value       = "kubectl -n ${module.jenkins.namespace} get secret ${module.jenkins.release_name} -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
}

output "jenkins_port_forward" {
  description = "Команда для доступу до Jenkins UI без публічного LoadBalancer"
  value       = "kubectl -n ${module.jenkins.namespace} port-forward svc/${module.jenkins.release_name} 8080:8080"
}

output "kaniko_iam_role_arn" {
  description = "ARN IAM-ролі, яку через IRSA використовує ServiceAccount kaniko для push в ECR"
  value       = module.jenkins.kaniko_role_arn
}

output "rds_endpoint" {
  description = "Endpoint для запису (writer) — host бази даних, без порту"
  value       = module.rds.endpoint
}

output "rds_reader_endpoint" {
  description = "Endpoint для читання (заповнений лише коли rds_use_aurora = true)"
  value       = module.rds.reader_endpoint
}

output "rds_port" {
  description = "Порт бази даних"
  value       = module.rds.port
}

output "rds_db_name" {
  description = "Назва бази даних"
  value       = module.rds.db_name
}

output "rds_master_user_secret_arn" {
  description = "ARN секрету в Secrets Manager з паролем адміністратора БД"
  value       = module.rds.master_user_secret_arn
}

output "rds_security_group_id" {
  description = "ID security group бази даних"
  value       = module.rds.security_group_id
}

output "argocd_namespace" {
  description = "Namespace, у якому встановлено Argo CD"
  value       = module.argo_cd.namespace
}

output "argocd_url" {
  description = "Command to get Argo CD UI URL"
  value       = "kubectl -n ${module.argo_cd.namespace} get svc ${module.argo_cd.release_name}-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_get_admin_password" {
  description = "Command to retrieve the initial Argo CD admin password"
  value       = "kubectl -n ${module.argo_cd.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_port_forward" {
  description = "Команда для доступу до Argo CD UI без публічного LoadBalancer"
  value       = "kubectl -n ${module.argo_cd.namespace} port-forward svc/${module.argo_cd.release_name}-server 8081:443"
}
