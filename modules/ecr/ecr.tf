data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = var.repository_name
    Project = var.project_name
  }
}

# Basic repository policy: allows pull/push only to principals within this
# same AWS account (account root, which covers any IAM user/role with the
# relevant ecr:* IAM permissions). For a real multi-account/CI setup, replace
# the Principal with specific IAM role ARNs (e.g. a CI/CD deployment role or
# the EKS node IAM role) instead of the account root.
resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountPullPush"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
      }
    ]
  })
}

# Optional lifecycle policy: keeps only the N most recent images so storage
# cost doesn't grow unbounded. Disabled (no resource created) when
# max_image_count = 0, in case you'd rather manage retention manually.
resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.max_image_count > 0 ? 1 : 0
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
