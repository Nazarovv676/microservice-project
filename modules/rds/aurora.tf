# ------------------------------------------------------------------------------
# Aurora-кластер (use_aurora = true): writer + за потреби readers
# ------------------------------------------------------------------------------

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name   = "${local.name}-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
      # Той самий фікс, що й у rds.tf: "immediate" падає на static-параметрах
      # (напр. max_connections) з InvalidParameterCombination.
      apply_method = "pending-reboot"
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = local.name

  engine         = local.aurora_engine
  engine_version = var.engine_version

  database_name   = var.db_name
  master_username = var.master_username

  manage_master_user_password = var.manage_master_user_password ? true : null
  master_password             = var.manage_master_user_password ? null : var.master_password

  port                            = local.port
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  storage_encrypted = var.storage_encrypted

  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  apply_immediately         = var.apply_immediately
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-final-snapshot"

  tags = local.tags
}

# Перший instance (count.index == 0) — writer; решта, якщо aurora_instance_count > 1, — readers.
resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${local.name}-${count.index}"
  cluster_identifier = aws_rds_cluster.this[0].id

  engine         = local.aurora_engine
  engine_version = aws_rds_cluster.this[0].engine_version
  instance_class = var.instance_class

  publicly_accessible = var.publicly_accessible
  apply_immediately   = var.apply_immediately

  tags = merge(local.tags, {
    Role = count.index == 0 ? "writer" : "reader"
  })
}
