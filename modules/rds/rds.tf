# ------------------------------------------------------------------------------
# Звичайна RDS-інстанція (use_aurora = false)
# ------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  count = var.use_aurora ? 0 : 1

  name   = "${local.name}-params"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier = local.name

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted

  db_name  = var.db_name
  username = var.master_username

  manage_master_user_password = var.manage_master_user_password ? true : null
  password                    = var.manage_master_user_password ? null : var.master_password

  port                   = local.port
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible
  apply_immediately   = var.apply_immediately

  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-final-snapshot"

  tags = local.tags
}
