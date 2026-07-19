output "state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = module.s3_backend.bucket_name
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket storing Terraform state"
  value       = module.s3_backend.bucket_arn
}

output "state_lock_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = module.s3_backend.lock_table_name
}

output "vpc_id" {
  description = "ID of the created VPC"
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
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}
