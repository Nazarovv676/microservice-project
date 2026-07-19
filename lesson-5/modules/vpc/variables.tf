variable "project_name" {
  description = "Project name used for tagging/naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ (same order as availability_zones)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ (same order as availability_zones)"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway for all private subnets instead of one per AZ (cost saving vs. high-availability trade-off)"
  type        = bool
  default     = true
}
