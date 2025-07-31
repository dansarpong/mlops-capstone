
locals {

  # Use provided name or generate one
  security_group_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name
}
