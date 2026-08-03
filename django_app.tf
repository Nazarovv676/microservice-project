# Django (charts/django-app) деплоїться через Argo CD напряму з git (GitOps,
# див. modules/argo_cd) — Terraform не керує самим helm-релізом. Але без
# цього ресурсу POSTGRES_HOST/PASSWORD у values.yaml лишались би статичним
# плейсхолдером, і Django не міг би автоматично приєднатись до RDS.
# Тому тут рендериться сам файл values.yaml з шаблону values.yaml.tpl,
# підставляючи реальні endpoint/port/db_name/username/password з module.rds.
# Після terraform apply перегенерований values.yaml потрібно закомітити й
# запушити (як і бамп image.tag у Jenkinsfile) — тоді Argo CD (selfHeal)
# підхопить його автоматично.
resource "local_file" "django_app_values" {
  filename = "${path.module}/charts/django-app/values.yaml"

  content = templatefile("${path.module}/charts/django-app/values.yaml.tpl", {
    postgres_host     = module.rds.endpoint
    postgres_port     = module.rds.port
    postgres_db       = module.rds.db_name
    postgres_user     = module.rds.master_username
    postgres_password = module.rds.master_password
  })

  file_permission = "0644"
}
