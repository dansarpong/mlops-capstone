# IAM Role
resource "aws_iam_role" "this" {
  name                 = local.role_name
  path                 = var.path
  description          = var.description
  max_session_duration = var.max_session_duration

  force_detach_policies = var.force_detach_policies
  permissions_boundary  = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge(
        {
          Effect = "Allow"
          Action = var.trusted_role_actions
          Principal = merge(
            var.federated_principal != null ? { Federated = var.federated_principal } : {},
            length(var.trusted_role_services) > 0 ? { Service = var.trusted_role_services } : {},
            length(var.trusted_role_arns) > 0 ? { AWS = var.trusted_role_arns } : {}
          )
        },
        var.federated_conditions != null ? { Condition = var.federated_conditions } : {}
      )
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = local.role_name
    }
  )
}

# Custom Policies
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = "${local.role_name}-${each.key}"
  path        = var.path
  description = "Policy ${each.key} for role ${local.role_name}"
  policy      = each.value

  tags = merge(
    var.tags,
    {
      Name = "${local.role_name}-${each.key}"
    }
  )
}

# Attach custom policies
resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.policies

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = local.instance_profile_name
  path = var.path
  role = aws_iam_role.this.name

  tags = merge(
    var.tags,
    {
      Name = local.instance_profile_name
    }
  )
}
