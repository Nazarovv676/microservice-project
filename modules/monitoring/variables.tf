variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace для Prometheus/Grafana"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Версія Helm-чарта prometheus-community/kube-prometheus-stack"
  type        = string
}

variable "grafana_service_type" {
  description = "Тип Service для Grafana"
  type        = string
  default     = "LoadBalancer"
}

variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana. За замовчуванням чарт сам генерує Secret <release>-grafana — лишай порожнім, якщо не треба фіксоване значення"
  type        = string
  sensitive   = true
  default     = ""
}

variable "storage_class" {
  description = "StorageClass для PVC Prometheus/Grafana (кластер має in-tree \"gp2\" за замовчуванням — так само, як modules/jenkins)"
  type        = string
  default     = "gp2"
}

variable "prometheus_retention" {
  description = "Скільки часу Prometheus зберігає метрики"
  type        = string
  default     = "5d"
}

variable "prometheus_storage_size" {
  description = "Розмір PVC для Prometheus TSDB"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_size" {
  description = "Розмір PVC для Grafana (дашборди/налаштування)"
  type        = string
  default     = "2Gi"
}
