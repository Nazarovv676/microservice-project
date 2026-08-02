variable "project_name" {
  description = "Project name used as a prefix for resource naming/tags"
  type        = string
}

variable "identifier" {
  description = "Base identifier for the database resources (subnet group, security group, RDS instance/Aurora cluster)"
  type        = string
}

variable "tags" {
  description = "Extra tags merged into every resource created by this module"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC the database is deployed into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (typically private subnets, at least 2 in different AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS/Aurora needs a subnet group spanning at least 2 subnets in different Availability Zones."
  }
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to reach the database on var.port (e.g. the EKS cluster/node security group)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the database on var.port, in addition to allowed_security_group_ids"
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Port the database listens on. Defaults to the engine's standard port (5432 for postgres, 3306 for mysql) when left null"
  type        = number
  default     = null
}

# ------------------------------------------------------------------------------
# Engine selection — це і є перемикач Aurora vs. звичайна RDS-інстанція
# ------------------------------------------------------------------------------

variable "use_aurora" {
  description = "true — підняти Aurora-кластер (writer + за потреби readers); false — звичайна одиночна aws_db_instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Сімейство БД: \"postgres\" або \"mysql\". Для Aurora модуль сам підставляє відповідний aurora-postgresql/aurora-mysql engine"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be either \"postgres\" or \"mysql\"."
  }
}

variable "engine_version" {
  description = "Версія engine (напр. \"16.4\" для postgres, \"8.0.mysql_aurora.3.08.0\" для aurora-mysql тощо)"
  type        = string
  default     = "16.4"
}

variable "parameter_group_family" {
  description = <<-EOT
    Родина parameter group, яку вимагає AWS (напр. "postgres16", "mysql8.0",
    "aurora-postgresql16", "aurora-mysql8.0"). Має відповідати і engine, і
    use_aurora — AWS не виводить її автоматично з engine_version, тому це
    окрема змінна. Дивись README модуля за прикладами.
  EOT
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "Клас інстансу (для звичайної RDS — сам instance; для Aurora — клас кожного cluster instance)"
  type        = string
  default     = "db.t3.medium"
}

# ------------------------------------------------------------------------------
# Звичайна RDS (use_aurora = false)
# ------------------------------------------------------------------------------

variable "allocated_storage" {
  description = "Розмір сховища в GiB (тільки для звичайної RDS-інстанції; Aurora масштабує сховище автоматично)"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Тип сховища для звичайної RDS-інстанції (gp3, gp2, io1, ...)"
  type        = string
  default     = "gp3"
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ standby для звичайної RDS-інстанції (ігнорується для Aurora — там висока доступність через кількість instance'ів у кластері)"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# Aurora (use_aurora = true)
# ------------------------------------------------------------------------------

variable "aurora_instance_count" {
  description = "Кількість instance'ів в Aurora-кластері: перший завжди writer, решта — readers"
  type        = number
  default     = 1

  validation {
    condition     = var.aurora_instance_count >= 1
    error_message = "aurora_instance_count must be at least 1 (the writer)."
  }
}

# ------------------------------------------------------------------------------
# Database / credentials
# ------------------------------------------------------------------------------

variable "db_name" {
  description = "Назва бази даних, що створюється всередині instance/cluster"
  type        = string
}

variable "master_username" {
  description = "Master username адміністратора БД"
  type        = string
  default     = "app_admin"
}

variable "manage_master_user_password" {
  description = "true (за замовчуванням) — AWS сам генерує і зберігає пароль у Secrets Manager (master_password ігнорується); false — пароль береться з master_password"
  type        = bool
  default     = true
}

variable "master_password" {
  description = "Master password (використовується лише коли manage_master_user_password = false). Ніколи не комітиться — передавай через terraform.tfvars або -var"
  type        = string
  default     = null
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Parameter group
# ------------------------------------------------------------------------------

variable "db_parameters" {
  description = "Параметри для DB/Cluster parameter group. Дефолт розрахований на PostgreSQL — для MySQL підстав власний список (напр. general_log, sort_buffer_size)"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    { name = "max_connections", value = "100" },
    { name = "log_statement", value = "all" },
    { name = "work_mem", value = "4096" },
  ]
}

# ------------------------------------------------------------------------------
# Operational settings
# ------------------------------------------------------------------------------

variable "backup_retention_period" {
  description = "Кількість днів зберігання автоматичних бекапів"
  type        = number
  default     = 7
}

variable "storage_encrypted" {
  description = "Шифрувати сховище БД (KMS)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Захист від випадкового видалення instance/cluster (вимкни явно перед terraform destroy)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Пропустити фінальний снапшот при видаленні. false — безпечніше для прода, але потребує ручного прибирання снапшотів"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Видати instance/cluster публічну IP-адресу (для навчального проєкту завжди тримай false)"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Застосовувати зміни одразу замість maintenance window (корисно для дев-середовищ, ризиковано для прода)"
  type        = bool
  default     = false
}
