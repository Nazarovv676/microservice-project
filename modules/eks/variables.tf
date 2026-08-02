variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "ID of the VPC the cluster is deployed into"
  type        = string
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs attached to the EKS control plane ENIs (public + private)"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet IDs for the managed node group (private subnets)"
  type        = list(string)
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
