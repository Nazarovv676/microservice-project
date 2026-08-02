output "namespace" {
  description = "Namespace, у якому встановлено Jenkins"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "release_name" {
  description = "Ім'я Helm-релізу Jenkins (використовується у назвах Service/Pod)"
  value       = helm_release.jenkins.name
}

output "kaniko_service_account" {
  description = "Ім'я ServiceAccount з IRSA-роллю для push в ECR — його має вказувати serviceAccountName пода агента в Jenkinsfile"
  value       = kubernetes_service_account.kaniko.metadata[0].name
}

output "kaniko_role_arn" {
  description = "ARN IAM-ролі, яку через IRSA отримує ServiceAccount kaniko"
  value       = aws_iam_role.kaniko.arn
}
