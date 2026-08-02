# Провайдери конфігуруються один раз у корені (lesson-8-9/providers.tf) —
# тут лише декларація версій, яких потребує цей модуль.
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}
