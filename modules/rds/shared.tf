# ------------------------------------------------------------------------------
# Спільні ресурси для обох режимів (use_aurora = true/false): subnet group,
# security group і базові локальні значення (ім'я, порт, теги).
# ------------------------------------------------------------------------------

locals {
  name = "${var.project_name}-${var.identifier}"

  default_port = var.engine == "postgres" ? 5432 : 3306
  port         = coalesce(var.port, local.default_port)

  aurora_engine = var.engine == "postgres" ? "aurora-postgresql" : "aurora-mysql"

  tags = merge(
    {
      Project = var.project_name
      Module  = "rds"
    },
    var.tags,
  )
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.tags, {
    Name = "${local.name}-subnet-group"
  })
}

resource "aws_security_group" "this" {
  name        = "${local.name}-sg"
  description = "Access to the ${local.name} database (port ${local.port})"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_security_groups" {
  # count замість for_each: значення allowed_security_group_ids (напр.
  # module.eks.cluster_security_group_id) невідомі до apply при розгортанні
  # з нуля, а for_each вимагає відомих ключів вже на етапі plan. count
  # потребує лише довжину списку, яка відома завжди.
  count = length(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.allowed_security_group_ids[count.index]
  description              = "DB access from security group ${var.allowed_security_group_ids[count.index]}"
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.allowed_cidr_blocks
  description       = "DB access from allowed_cidr_blocks"
}
