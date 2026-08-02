resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = var.project_name
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # kube-prometheus-stack тягне CRD Prometheus Operator (Prometheus,
  # Alertmanager, ServiceMonitor, ...) — Helm 3 інсталює CRD з чарта
  # автоматично при першому релізі.
  values = [
    templatefile("${path.module}/values.yaml", {
      grafana_service_type    = var.grafana_service_type
      grafana_admin_password  = var.grafana_admin_password
      storage_class           = var.storage_class
      prometheus_retention    = var.prometheus_retention
      prometheus_storage_size = var.prometheus_storage_size
      grafana_storage_size    = var.grafana_storage_size
    })
  ]
}
