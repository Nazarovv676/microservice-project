resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = var.project_name
    }
  }
}

# ------------------------------------------------------------------------------
# IAM-роль для ServiceAccount "kaniko" (namespace jenkins) — довіра обмежена
# конкретним SA через умову на "sub"/"aud" з OIDC-токена (IRSA), без
# статичних AWS-ключів у Jenkins. Використовує IAM OIDC provider, який уже
# зареєстрував модуль eks (aws_ebs_csi_driver.tf) — AWS дозволяє лише один
# provider на issuer URL кластера, тож тут його не дублюємо, а приймаємо
# ARN/host через var.oidc_provider_arn / var.oidc_provider_host.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "kaniko" {
  name = "${var.project_name}-kaniko-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_host}:sub" = "system:serviceaccount:${var.namespace}:${var.kaniko_service_account_name}"
            "${var.oidc_provider_host}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# Мінімально необхідні права для Kaniko: push образу в конкретний ECR-репозиторій.
# GetAuthorizationToken не підтримує resource-level обмеження (діє на весь
# акаунт), тому винесений в окремий statement з Resource "*".
resource "aws_iam_role_policy" "kaniko_ecr_push" {
  name = "${var.project_name}-kaniko-ecr-push"
  role = aws_iam_role.kaniko.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "kubernetes_service_account" "kaniko" {
  metadata {
    name      = var.kaniko_service_account_name
    namespace = kubernetes_namespace.jenkins.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kaniko.arn
    }
  }
}
