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
