# Мережа (VPC, підмережі) береться з уже застосованого стейту lesson-5 —
# новий VPC тут НЕ створюється, щоб не плодити другий NAT Gateway/VPC і щоб
# кластер жив у тій самій мережі, як і вимагає завдання.
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.vpc_state_bucket
    key    = var.vpc_state_key
    region = var.aws_region
  }
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

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  # Control plane ENI підключаються і до публічних, і до приватних підмереж.
  control_plane_subnet_ids = concat(
    data.terraform_remote_state.network.outputs.public_subnet_ids,
    data.terraform_remote_state.network.outputs.private_subnet_ids,
  )

  # Worker-ноди живуть у приватних підмережах (вихід в інтернет через NAT
  # Gateway з lesson-5, вхідний трафік — лише через Service/Ingress).
  node_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}
