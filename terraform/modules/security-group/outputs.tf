# Security Group Outputs
output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.this.arn
}

output "security_group_vpc_id" {
  description = "The VPC ID of the security group"
  value       = aws_security_group.this.vpc_id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.this.name
}

output "security_group_description" {
  description = "The description of the security group"
  value       = aws_security_group.this.description
}

output "security_group_owner_id" {
  description = "The owner ID of the security group"
  value       = aws_security_group.this.owner_id
}

# Ingress Rule Outputs
output "ingress_with_cidr_blocks_security_group_rule_ids" {
  description = "IDs of the ingress security group rules with CIDR blocks"
  value       = { for k, v in aws_security_group_rule.ingress_with_cidr_blocks : k => v.id }
}

output "ingress_with_source_security_group_id_security_group_rule_ids" {
  description = "IDs of the ingress security group rules with source security group ID"
  value       = { for k, v in aws_security_group_rule.ingress_with_source_security_group_id : k => v.id }
}

output "ingress_with_self_security_group_rule_ids" {
  description = "IDs of the ingress security group rules with self"
  value       = { for k, v in aws_security_group_rule.ingress_with_self : k => v.id }
}

output "ingress_with_prefix_list_ids_security_group_rule_ids" {
  description = "IDs of the ingress security group rules with prefix list IDs"
  value       = { for k, v in aws_security_group_rule.ingress_with_prefix_list_ids : k => v.id }
}

# Egress Rule Outputs
output "egress_with_cidr_blocks_security_group_rule_ids" {
  description = "IDs of the egress security group rules with CIDR blocks"
  value       = { for k, v in aws_security_group_rule.egress_with_cidr_blocks : k => v.id }
}

output "egress_with_source_security_group_id_security_group_rule_ids" {
  description = "IDs of the egress security group rules with source security group ID"
  value       = { for k, v in aws_security_group_rule.egress_with_source_security_group_id : k => v.id }
}

output "egress_with_self_security_group_rule_ids" {
  description = "IDs of the egress security group rules with self"
  value       = { for k, v in aws_security_group_rule.egress_with_self : k => v.id }
}

output "egress_with_prefix_list_ids_security_group_rule_ids" {
  description = "IDs of the egress security group rules with prefix list IDs"
  value       = { for k, v in aws_security_group_rule.egress_with_prefix_list_ids : k => v.id }
}

# Default Egress Rule Output
output "default_egress_security_group_rule_id" {
  description = "ID of the default egress security group rule"
  value       = length(aws_security_group_rule.default_egress) > 0 ? aws_security_group_rule.default_egress[0].id : null
}
