module "s3_backend" {
  source = "./modules/s3-backend"

  bucket_name     = var.state_bucket_name
  lock_table_name = var.state_lock_table_name
  project_name    = var.project_name
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}

module "ecr" {
  source = "./modules/ecr"

  repository_name      = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  max_image_count      = var.ecr_max_image_count
  project_name         = var.project_name
}

module "eks" {
  source = "./modules/eks"

  project_name    = var.project_name
  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id = module.vpc.vpc_id

  # Control plane ENI підключаються і до публічних, і до приватних підмереж.
  control_plane_subnet_ids = concat(
    module.vpc.public_subnet_ids,
    module.vpc.private_subnet_ids,
  )

  # Worker-ноди живуть у приватних підмережах (вихід в інтернет через NAT
  # Gateway, вхідний трафік — лише через Service/Ingress).
  node_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}

# Короткоживучий токен для доступу kubernetes/helm-провайдерів до кластера —
# без залежності від локального ~/.kube/config (див. providers.tf).
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

module "jenkins" {
  source = "./modules/jenkins"

  project_name  = var.project_name
  namespace     = var.jenkins_namespace
  chart_version = var.jenkins_chart_version
  service_type  = var.jenkins_service_type

  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_host = module.eks.oidc_provider_host
  ecr_repository_arn = module.ecr.repository_arn
  ecr_repository_url = module.ecr.repository_url

  github_owner    = var.github_owner
  github_repo     = var.github_repo
  github_username = var.github_username
  github_pat      = var.github_pat

  # Явна залежність від усього модуля eks (не лише від використаних output'ів)
  # — Jenkins-у потрібен готовий aws-ebs-csi-driver addon (з aws_ebs_csi_driver.tf)
  # для власного PVC, а посилання лише на oidc_provider_* цього не гарантує.
  depends_on = [module.eks]
}

module "argo_cd" {
  source = "./modules/argo_cd"

  project_name  = var.project_name
  namespace     = var.argocd_namespace
  chart_version = var.argocd_chart_version
  service_type  = var.argocd_server_service_type

  github_owner    = var.github_owner
  github_repo     = var.github_repo
  github_username = var.github_username
  github_pat      = var.github_pat

  app_name            = "django-app"
  app_chart_path      = var.app_chart_path
  app_target_revision = var.app_target_revision
  app_destination_ns  = var.app_namespace

  depends_on = [module.eks]
}
