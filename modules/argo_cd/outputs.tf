output "namespace" {
  description = "Namespace, у якому встановлено Argo CD"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  description = "Ім'я Helm-релізу Argo CD (використовується у назвах Service/Pod)"
  value       = helm_release.argocd.name
}

output "application_name" {
  description = "Ім'я Argo CD Application для django-app"
  value       = var.app_name
}
