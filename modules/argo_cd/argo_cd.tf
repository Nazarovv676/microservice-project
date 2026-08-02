resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = var.project_name
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      service_type = var.service_type
    })
  ]
}

# "App-of-apps": невеликий локальний Helm-чарт (charts/argocd-apps), що
# оголошує Argo CD Application для django-app + Secret з креденшелами
# репозиторію — так само, як структуровано в завданні
# (modules/argo_cd/charts/...).
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts/argocd-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      applications = [
        {
          name                 = var.app_name
          repoURL              = "https://github.com/${var.github_owner}/${var.github_repo}.git"
          path                 = var.app_chart_path
          targetRevision       = var.app_target_revision
          destinationNamespace = var.app_destination_ns
        }
      ]
      repository = {
        name     = "${var.app_name}-repo"
        url      = "https://github.com/${var.github_owner}/${var.github_repo}.git"
        username = var.github_username
        password = var.github_pat
      }
    })
  ]

  depends_on = [helm_release.argocd]
}
