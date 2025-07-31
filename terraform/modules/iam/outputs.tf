# IAM Role Outputs
output "role_id" {
  description = "The ID of the IAM role"
  value       = aws_iam_role.this.id
}

output "role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_path" {
  description = "The path of the IAM role"
  value       = aws_iam_role.this.path
}

output "role_unique_id" {
  description = "The unique ID of the IAM role"
  value       = aws_iam_role.this.unique_id
}

# IAM Policy Outputs
output "policy_ids" {
  description = "List of IDs of the IAM policies"
  value       = [for policy in aws_iam_policy.this : policy.id]
}

output "policy_arns" {
  description = "List of ARNs of the IAM policies"
  value       = [for policy in aws_iam_policy.this : policy.arn]
}

output "policy_names" {
  description = "List of names of the IAM policies"
  value       = [for policy in aws_iam_policy.this : policy.name]
}

# IAM Instance Profile Outputs
output "instance_profile_id" {
  description = "The ID of the IAM instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].id : null
}

output "instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].arn : null
}

output "instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].name : null
}

output "instance_profile_path" {
  description = "The path of the IAM instance profile"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].path : null
}
