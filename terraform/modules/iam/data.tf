
locals {

  # Use provided name or generate one
  role_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name

  # Use provided name or generate one
  instance_profile_name = var.instance_profile_name != null ? var.instance_profile_name : "${local.role_name}-profile"
}
