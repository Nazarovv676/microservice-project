variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that stores Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "lesson-5"
}
