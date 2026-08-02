# Секрет з GitHub-креденшелами для стадії "Update Helm chart & push" у
# Jenkinsfile. Лейбл/тип — конвенція плагіна kubernetes-credentials-provider:
# він сам знаходить такі Secret'и в namespace Jenkins і реєструє їх як
# Jenkins credential з id = ім'я Secret'а ("github-credentials") — без
# ручного створення credential через UI і без токена у values.yaml/JCasC.
resource "kubernetes_secret" "github_credentials" {
  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.jenkins.metadata[0].name

    labels = {
      "jenkins.io/credentials-type" = "usernamePassword"
    }

    annotations = {
      "jenkins.io/credentials-description" = "GitHub PAT для push у ${var.github_owner}/${var.github_repo}"
    }
  }

  data = {
    username = var.github_username
    password = var.github_pat
  }

  type = "Opaque"
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      service_type = var.service_type
    })
  ]

  depends_on = [
    kubernetes_service_account.kaniko,
    kubernetes_secret.github_credentials,
  ]
}
