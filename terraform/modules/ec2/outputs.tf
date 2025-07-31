output "id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "key_pair_name" {
  description = "The name of the key pair used for the EC2 instance."
  value       = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
}

output "private_key_pem" {
  description = "The private key in PEM format (only if a new key pair is created). Save this securely!"
  value       = var.create_key_pair ? tls_private_key.this[0].private_key_pem : null
  sensitive   = true
}

# Instance Scheduler Outputs
output "scheduler_enabled" {
  description = "Whether instance scheduler is enabled"
  value       = var.enable_instance_scheduler
}

output "scheduler_group_name" {
  description = "Name of the scheduler group"
  value       = var.enable_instance_scheduler ? aws_scheduler_schedule_group.this[0].name : null
}

output "start_schedule_name" {
  description = "Name of the start schedule"
  value       = var.enable_instance_scheduler ? aws_scheduler_schedule.start_instance[0].name : null
}

output "stop_schedule_name" {
  description = "Name of the stop schedule"
  value       = var.enable_instance_scheduler ? aws_scheduler_schedule.stop_instance[0].name : null
}

output "scheduler_role_arn" {
  description = "ARN of the scheduler IAM role"
  value       = var.enable_instance_scheduler ? var.scheduler_role_arn : null
}

# Elastic IP Outputs
output "elastic_ip_allocated" {
  description = "Whether an Elastic IP was allocated for this instance"
  value       = var.allocate_elastic_ip || var.existing_elastic_ip_id != null
}

output "elastic_ip_id" {
  description = "The allocation ID of the Elastic IP (if allocated or provided)"
  value       = var.existing_elastic_ip_id != null ? var.existing_elastic_ip_id : (var.allocate_elastic_ip ? aws_eip.this[0].id : null)
}

output "elastic_ip_address" {
  description = "The Elastic IP address (if allocated or provided)"
  value       = var.existing_elastic_ip_id != null ? data.aws_eip.existing[0].public_ip : (var.allocate_elastic_ip ? aws_eip.this[0].public_ip : null)
}

output "elastic_ip_public_dns" {
  description = "The public DNS name associated with the Elastic IP"
  value       = var.existing_elastic_ip_id != null ? data.aws_eip.existing[0].public_dns : (var.allocate_elastic_ip ? aws_eip.this[0].public_dns : null)
}
