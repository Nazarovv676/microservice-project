# kubernetes/helm-провайдери сконфігуровані ОДИН РАЗ тут, у корені (дочірні
# модулі jenkins/argo_cd лише декларують required_providers, без власного
# provider-блоку — конфігурація підключення до кластера не дублюється).
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
