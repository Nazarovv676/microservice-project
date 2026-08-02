variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used as a prefix for resource naming/tags"
  type        = string
  default     = "lesson-7"
}

# ------------------------------------------------------------------------------
# S3 backend (state + lock)
# ------------------------------------------------------------------------------

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state"
  type        = string
}

variable "state_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to deploy subnets into"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ, same order as availability_zones)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ, same order as availability_zones)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway for all private subnets instead of one per AZ (cost saving vs. high-availability trade-off)"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# ECR
# ------------------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the Django image"
  type        = string
  default     = "lesson-7-django-app"
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for the ECR repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_max_image_count" {
  description = "Maximum number of images to keep in the ECR repository via lifecycle policy (0 disables the policy)"
  type        = number
  default     = 10
}

# ------------------------------------------------------------------------------
# EKS
# ------------------------------------------------------------------------------

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "lesson-7-eks"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane (1.30 dropped out of AWS support entirely; keep this within STANDARD_SUPPORT — check `aws eks describe-cluster-versions`)"
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

# ------------------------------------------------------------------------------
# GitHub-репозиторій із застосунком і Helm-чартом (монорепо: Jenkins оновлює
# charts/django-app/values.yaml і пушить у гілку цього ж репозиторію; Argo CD
# теж стежить за ним).
# ------------------------------------------------------------------------------

variable "github_owner" {
  description = "Власник (org/user) GitHub-репозиторію"
  type        = string
}

variable "github_repo" {
  description = "Назва GitHub-репозиторію (без .git)"
  type        = string
}

variable "app_chart_path" {
  description = "Шлях до Helm-чарта застосунку всередині репозиторію"
  type        = string
  default     = "charts/django-app"
}

variable "app_target_revision" {
  description = "Гілка/тег, за якою стежить Argo CD Application. У цьому репозиторії кожен урок живе на власній гілці (main ніколи не мержиться), тому за замовчуванням це lesson-8-9, а не main"
  type        = string
  default     = "lesson-8-9"
}

variable "app_namespace" {
  description = "Namespace, у який Argo CD синхронізує django-app"
  type        = string
  default     = "default"
}

variable "github_username" {
  description = "GitHub username для push у main і (за потреби) для приватного клонування репозиторію Argo CD"
  type        = string
  sensitive   = true
}

variable "github_pat" {
  description = "GitHub Personal Access Token з правом push у репозиторій (scope: repo). Ніколи не комітиться — лише в terraform.tfvars, який у .gitignore"
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Jenkins
# ------------------------------------------------------------------------------

variable "jenkins_namespace" {
  description = "Kubernetes namespace для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_chart_version" {
  description = "Версія Helm-чарта jenkinsci/jenkins (5.7.5 бандлить застарілий Jenkins 2.462.3, з яким сучасні релізи плагінів вже несумісні — 5.9.x тягне 2.568.1)"
  type        = string
  default     = "5.9.45"
}

variable "jenkins_service_type" {
  description = "Тип Service для Jenkins controller (LoadBalancer, ClusterIP, ...)"
  type        = string
  default     = "LoadBalancer"
}

# ------------------------------------------------------------------------------
# Argo CD
# ------------------------------------------------------------------------------

variable "argocd_namespace" {
  description = "Kubernetes namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Версія Helm-чарта argo/argo-cd"
  type        = string
  default     = "7.7.11"
}

variable "argocd_server_service_type" {
  description = "Тип Service для Argo CD server (LoadBalancer, ClusterIP, ...)"
  type        = string
  default     = "LoadBalancer"
}

# ------------------------------------------------------------------------------
# RDS (universal module: звичайна RDS-інстанція або Aurora-кластер, залежно
# від rds_use_aurora — див. modules/rds/README.md)
# ------------------------------------------------------------------------------

variable "rds_identifier" {
  description = "Базовий identifier для ресурсів БД (subnet group, security group, instance/cluster)"
  type        = string
  default     = "django-db"
}

variable "rds_use_aurora" {
  description = "true — Aurora-кластер (writer + readers), false — звичайна одиночна RDS-інстанція"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "Сімейство БД: \"postgres\" або \"mysql\""
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Версія engine"
  type        = string
  default     = "16.4"
}

variable "rds_parameter_group_family" {
  description = "Родина parameter group; має відповідати rds_engine + rds_use_aurora (напр. postgres16 vs aurora-postgresql16)"
  type        = string
  default     = "postgres16"
}

variable "rds_instance_class" {
  description = "Клас інстансу БД"
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Розмір сховища в GiB (тільки для звичайної RDS-інстанції)"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Multi-AZ standby для звичайної RDS-інстанції"
  type        = bool
  default     = false
}

variable "rds_aurora_instance_count" {
  description = "Кількість instance'ів в Aurora-кластері (перший — writer, решта — readers)"
  type        = number
  default     = 1
}

variable "rds_db_name" {
  description = "Назва бази даних Django-застосунку"
  type        = string
  default     = "django_app"
}

variable "rds_master_username" {
  description = "Master username адміністратора БД"
  type        = string
  default     = "app_admin"
}

variable "rds_deletion_protection" {
  description = "Захист БД від випадкового видалення"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Пропустити фінальний снапшот при видаленні БД"
  type        = bool
  default     = true
}
