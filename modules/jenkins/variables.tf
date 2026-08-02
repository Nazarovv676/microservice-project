variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Версія Helm-чарта jenkinsci/jenkins"
  type        = string
}

variable "service_type" {
  description = "Тип Service для Jenkins controller"
  type        = string
  default     = "LoadBalancer"
}

variable "oidc_provider_arn" {
  description = "ARN IAM OIDC provider кластера (вивід module.eks.oidc_provider_arn) — той самий provider, що й для aws-ebs-csi-driver"
  type        = string
}

variable "oidc_provider_host" {
  description = "OIDC issuer host кластера без https:// (вивід module.eks.oidc_provider_host)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN ECR-репозиторію, куди Kaniko пушить образ"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL ECR-репозиторію — використовується у values.yaml/Jenkinsfile як destination"
  type        = string
}

variable "github_owner" {
  description = "Власник GitHub-репозиторію"
  type        = string
}

variable "github_repo" {
  description = "Назва GitHub-репозиторію"
  type        = string
}

variable "github_username" {
  description = "GitHub username для credential, яким pipeline пушить у main"
  type        = string
  sensitive   = true
}

variable "github_pat" {
  description = "GitHub PAT (scope repo) для credential, яким pipeline пушить у main"
  type        = string
  sensitive   = true
}

variable "kaniko_service_account_name" {
  description = "Ім'я ServiceAccount, яке Jenkinsfile ставить у serviceAccountName пода агента (лише контейнер kaniko отримує AWS-права через IRSA)"
  type        = string
  default     = "kaniko"
}
