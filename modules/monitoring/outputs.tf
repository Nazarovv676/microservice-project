output "namespace" {
  description = "Namespace, у якому встановлено Prometheus/Grafana"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "release_name" {
  description = "Ім'я Helm-релізу kube-prometheus-stack (використовується у назвах Service/Pod)"
  value       = helm_release.kube_prometheus_stack.name
}

output "grafana_service_name" {
  description = "Ім'я Service Grafana (release-name + '-grafana' — конвенція subchart'а)"
  value       = "${helm_release.kube_prometheus_stack.name}-grafana"
}
