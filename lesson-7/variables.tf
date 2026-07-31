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
# Мережа (VPC) з lesson-5 — кластер розгортається у ВЖЕ ІСНУЮЧІЙ мережі,
# тому тут немає модуля vpc, лише посилання на віддалений стейт lesson-5.
# ------------------------------------------------------------------------------

variable "vpc_state_bucket" {
  description = "Назва S3-бакета зі стейтом lesson-5 (те саме значення, що і state_bucket_name у lesson-5/terraform.tfvars)"
  type        = string
}

variable "vpc_state_key" {
  description = "Key стейту lesson-5 у S3-бакеті"
  type        = string
  default     = "lesson-5/terraform.tfstate"
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
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.30"
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
