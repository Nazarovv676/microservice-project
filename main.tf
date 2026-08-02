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
