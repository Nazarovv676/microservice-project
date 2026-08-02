variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (MUTABLE or IMMUTABLE). IMMUTABLE prevents overwriting a tag once pushed, which is safer for production."
  type        = string
  default     = "MUTABLE"
}

variable "max_image_count" {
  description = "Maximum number of images to retain via lifecycle policy. Set to 0 to disable the lifecycle policy entirely."
  type        = number
  default     = 10
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "lesson-7"
}
