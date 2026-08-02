variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія Helm-чарта argo/argo-cd"
  type        = string
}

variable "service_type" {
  description = "Тип Service для Argo CD server"
  type        = string
  default     = "LoadBalancer"
}

variable "github_owner" {
  description = "Власник GitHub-репозиторію з Helm-чартом застосунку"
  type        = string
}

variable "github_repo" {
  description = "Назва GitHub-репозиторію з Helm-чартом застосунку"
  type        = string
}

variable "github_username" {
  description = "GitHub username для доступу Argo CD до репозиторію"
  type        = string
  sensitive   = true
}

variable "github_pat" {
  description = "GitHub PAT для доступу Argo CD до репозиторію"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Ім'я Argo CD Application"
  type        = string
  default     = "django-app"
}

variable "app_chart_path" {
  description = "Шлях до Helm-чарта застосунку в репозиторії"
  type        = string
}

variable "app_target_revision" {
  description = "Гілка/тег, за якою стежить Application"
  type        = string
}

variable "app_destination_ns" {
  description = "Namespace, у який синхронізується застосунок"
  type        = string
}
