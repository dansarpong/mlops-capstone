# Security Group
resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = var.description
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(
    var.tags,
    {
      Name = local.security_group_name
    }
  )

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress Rules with CIDR Blocks
resource "aws_security_group_rule" "ingress_with_cidr_blocks" {
  for_each = var.ingress_with_cidr_blocks

  security_group_id = aws_security_group.this.id
  type              = "ingress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  cidr_blocks = lookup(each.value, "cidr_blocks", null)
}

# Ingress Rules with Source Security Group ID
resource "aws_security_group_rule" "ingress_with_source_security_group_id" {
  for_each = var.ingress_with_source_security_group_id

  security_group_id = aws_security_group.this.id
  type              = "ingress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}

# Ingress Rules with Self
resource "aws_security_group_rule" "ingress_with_self" {
  for_each = var.ingress_with_self

  security_group_id = aws_security_group.this.id
  type              = "ingress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  self = true
}

# Ingress Rules with Prefix List IDs
resource "aws_security_group_rule" "ingress_with_prefix_list_ids" {
  for_each = var.ingress_with_prefix_list_ids

  security_group_id = aws_security_group.this.id
  type              = "ingress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  prefix_list_ids = lookup(each.value, "prefix_list_ids", null)
}

# Egress Rules with CIDR Blocks
resource "aws_security_group_rule" "egress_with_cidr_blocks" {
  for_each = var.egress_with_cidr_blocks

  security_group_id = aws_security_group.this.id
  type              = "egress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  cidr_blocks = lookup(each.value, "cidr_blocks", null)
}

# Egress Rules with Source Security Group ID
resource "aws_security_group_rule" "egress_with_source_security_group_id" {
  for_each = var.egress_with_source_security_group_id

  security_group_id = aws_security_group.this.id
  type              = "egress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}

# Egress Rules with Self
resource "aws_security_group_rule" "egress_with_self" {
  for_each = var.egress_with_self

  security_group_id = aws_security_group.this.id
  type              = "egress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  self = true
}

# Egress Rules with Prefix List IDs
resource "aws_security_group_rule" "egress_with_prefix_list_ids" {
  for_each = var.egress_with_prefix_list_ids

  security_group_id = aws_security_group.this.id
  type              = "egress"

  from_port   = lookup(each.value, "from_port", 0)
  to_port     = lookup(each.value, "to_port", 0)
  protocol    = lookup(each.value, "protocol", "-1")
  description = lookup(each.value, "description", null)

  prefix_list_ids = lookup(each.value, "prefix_list_ids", null)
}

# Default Egress Rule
resource "aws_security_group_rule" "default_egress" {
  count = var.create_default_egress_rule && length(var.egress_with_cidr_blocks) == 0 && length(var.egress_with_source_security_group_id) == 0 && length(var.egress_with_self) == 0 && length(var.egress_with_prefix_list_ids) == 0 ? 1 : 0

  security_group_id = aws_security_group.this.id
  type              = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic"
}
