# Плагін kubernetes-credentials-provider (values.yaml) шукає Kubernetes
# Secret'и, позначені лейблом jenkins.io/credentials-type, у namespace
# контролера — але дефолтний RBAC чарта jenkinsci/jenkins дає
# ServiceAccount "jenkins" лише права на створення подів агентів
# (jenkins-schedule-agents) і читання ConfigMap для JCasC-reload
# (jenkins-casc-reload), без права читати Secret'и. Без цього кроку
# Jenkinsfile падає на "Could not find credentials entry with ID
# 'github-credentials'".
resource "kubernetes_role" "jenkins_read_secrets" {
  metadata {
    name      = "jenkins-read-secrets"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "jenkins_read_secrets" {
  metadata {
    name      = "jenkins-read-secrets"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.jenkins_read_secrets.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}
