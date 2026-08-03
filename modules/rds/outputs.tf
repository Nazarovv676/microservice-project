output "endpoint" {
  description = "Endpoint для запису (writer). Для звичайної RDS — endpoint instance'у, для Aurora — cluster (writer) endpoint"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "reader_endpoint" {
  description = "Endpoint для читання, що балансує між readers. Заповнений лише коли use_aurora = true, інакше null"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "port" {
  description = "Порт, на якому слухає БД"
  value       = local.port
}

output "db_name" {
  description = "Назва бази даних всередині instance/cluster"
  value       = var.db_name
}

output "master_username" {
  description = "Master username адміністратора БД"
  value       = var.master_username
}

output "master_user_secret_arn" {
  description = "ARN секрету в Secrets Manager з паролем (заповнений лише коли manage_master_user_password = true)"
  value = var.manage_master_user_password ? (
    var.use_aurora
    ? try(aws_rds_cluster.this[0].master_user_secret[0].secret_arn, null)
    : try(aws_db_instance.this[0].master_user_secret[0].secret_arn, null)
  ) : null
}

# Реальний пароль у відкритому вигляді — потрібен, щоб кореневий модуль міг
# автоматично підставити POSTGRES_PASSWORD у charts/django-app/values.yaml
# (див. values.yaml.tpl + django_app.tf), без ручного копіювання з Secrets
# Manager. Коли manage_master_user_password = true, читаємо значення з того ж
# секрету, ARN якого повертає master_user_secret_arn вище.
data "aws_secretsmanager_secret_version" "master_password" {
  count = var.manage_master_user_password ? 1 : 0

  secret_id = var.use_aurora ? aws_rds_cluster.this[0].master_user_secret[0].secret_arn : aws_db_instance.this[0].master_user_secret[0].secret_arn
}

output "master_password" {
  description = "Пароль адміністратора БД у відкритому вигляді (з Secrets Manager коли manage_master_user_password = true, інакше з var.master_password)"
  value = var.manage_master_user_password ? (
    jsondecode(data.aws_secretsmanager_secret_version.master_password[0].secret_string)["password"]
  ) : var.master_password
  sensitive = true
}

output "security_group_id" {
  description = "ID security group бази даних"
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Ім'я DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Ім'я parameter group (звичайної або cluster — залежно від use_aurora)"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.this[0].name : aws_db_parameter_group.this[0].name
}

output "cluster_instance_identifiers" {
  description = "Identifiers усіх instance'ів Aurora-кластера (writer + readers). Порожній список, якщо use_aurora = false"
  value       = var.use_aurora ? aws_rds_cluster_instance.this[*].identifier : []
}
