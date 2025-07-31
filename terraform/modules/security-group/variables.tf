variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to the security group name"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
}

variable "revoke_rules_on_delete" {
  description = "Instruct Terraform to revoke all of the Security Group's attached ingress and egress rules before deleting the security group itself"
  type        = bool
  default     = false
}

# Ingress Rules
variable "ingress_with_cidr_blocks" {
  description = "Map of ingress rules to create with cidr_blocks"
  type        = map(any)
  default     = {}
}

variable "ingress_with_source_security_group_id" {
  description = "Map of ingress rules to create with source_security_group_id"
  type        = map(any)
  default     = {}
}

variable "ingress_with_self" {
  description = "Map of ingress rules to create with self"
  type        = map(any)
  default     = {}
}

variable "ingress_with_prefix_list_ids" {
  description = "Map of ingress rules to create with prefix_list_ids"
  type        = map(any)
  default     = {}
}

# Egress Rules
variable "egress_with_cidr_blocks" {
  description = "Map of egress rules to create with cidr_blocks"
  type        = map(any)
  default     = {}
}

variable "egress_with_source_security_group_id" {
  description = "Map of egress rules to create with source_security_group_id"
  type        = map(any)
  default     = {}
}

variable "egress_with_self" {
  description = "Map of egress rules to create with self"
  type        = map(any)
  default     = {}
}

variable "egress_with_prefix_list_ids" {
  description = "Map of egress rules to create with prefix_list_ids"
  type        = map(any)
  default     = {}
}

# Default Rules
variable "create_default_egress_rule" {
  description = "Whether to create default egress rule (allow all outbound traffic)"
  type        = bool
  default     = true
}

# Timeouts
variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting security group resources"
  type        = map(string)
  default     = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
