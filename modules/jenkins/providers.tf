# Провайдери kubernetes/helm/aws конфігуруються ОДИН РАЗ у корені
# (providers.tf) і успадковуються дочірніми модулями. Тут лише декларація
# версій, яких потребує цей модуль — без окремого provider-блоку, щоб не
# дублювати підключення до кластера.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
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
