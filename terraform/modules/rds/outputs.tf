# DB Instance Outputs
output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = local.is_primary ? aws_db_instance.this[0].address : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].address : null)
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = local.is_primary ? aws_db_instance.this[0].arn : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].arn : null)
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = local.is_primary ? aws_db_instance.this[0].endpoint : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].endpoint : null)
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = local.is_primary ? aws_db_instance.this[0].id : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].id : null)
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = local.is_primary ? aws_db_instance.this[0].identifier : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].identifier : null)
}

output "db_instance_name" {
  description = "The database name"
  value       = local.is_primary ? aws_db_instance.this[0].db_name : null
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = local.is_primary ? aws_db_instance.this[0].username : null
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = local.is_primary ? aws_db_instance.this[0].port : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].port : null)
}

output "db_instance_ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  value       = local.is_primary ? aws_db_instance.this[0].ca_cert_identifier : (length(aws_db_instance.replica) > 0 ? aws_db_instance.replica[0].ca_cert_identifier : null)
}

output "db_instance_master_user_secret_arn" {
  description = "The ARN of the master user secret (Only available when manage_master_user_password is set to true)"
  value       = local.is_primary && var.manage_master_user_password ? aws_db_instance.this[0].master_user_secret[0].secret_arn : null
}

# DB Subnet Group Outputs
output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].id : var.db_subnet_group_name
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].arn : null
}

# DB Parameter Group Outputs
output "db_parameter_group_id" {
  description = "The db parameter group name"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].id : var.parameter_group_name
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].arn : null
}

# DB Option Group Outputs
output "db_option_group_id" {
  description = "The db option group name"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].id : var.option_group_name
}

output "db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].arn : null
}

# Enhanced Monitoring Outputs
output "enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) of the enhanced monitoring role"
  value       = var.monitoring_role_arn
}

# Managed Master User Password Outputs
output "master_user_secret_arn" {
  description = "The ARN of the master user secret (Only available when manage_master_user_password is set to true)"
  value       = local.is_primary && var.manage_master_user_password ? aws_db_instance.this[0].master_user_secret[0].secret_arn : null
}
