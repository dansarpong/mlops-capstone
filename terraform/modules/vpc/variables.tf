variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "main"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "CIDR block for public subnets (used when public_subnet_cidrs is not specified)"
  type        = string
  default     = "10.0.0.0/20"
}

variable "private_subnets_cidr" {
  description = "CIDR block for private subnets (used when private_subnet_cidrs is not specified)"
  type        = string
  default     = "10.0.16.0/20"
}

variable "app_subnets_cidr" {
  description = "CIDR block for app subnets (used when app_subnet_cidrs is not specified)"
  type        = string
  default     = "10.0.32.0/20"
}

variable "database_subnets_cidr" {
  description = "CIDR block for database subnets (used when database_subnet_cidrs is not specified)"
  type        = string
  default     = "10.0.64.0/20"
}

variable "public_subnet_cidrs" {
  description = "List of specific CIDR blocks for public subnets. If empty, subnets will be automatically calculated from public_subnets_cidr"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of specific CIDR blocks for private subnets. If empty, subnets will be automatically calculated from private_subnets_cidr"
  type        = list(string)
  default     = []
}

variable "app_subnet_cidrs" {
  description = "List of specific CIDR blocks for app subnets. If empty, subnets will be automatically calculated from app_subnets_cidr"
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "List of specific CIDR blocks for database subnets. If empty, subnets will be automatically calculated from database_subnets_cidr"
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "AZ count must be between 2 and 6."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use. If empty, will automatically select available AZs up to az_count"
  type        = list(string)
  default     = []
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the subnet CIDR"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets (cost savings)"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets (set to false to disable NAT gateways completely)"
  type        = bool
  default     = true
}

variable "create_subnet_types" {
  description = "List of subnet types to create (valid values: public, private, app, database)"
  type        = list(string)
  default     = ["public", "private"]
  validation {
    condition     = length([for type in var.create_subnet_types : type if contains(["public", "private", "app", "database"], type)]) == length(var.create_subnet_types)
    error_message = "Valid values for create_subnet_types are 'public', 'private', 'app', and 'database'."
  }
}

variable "create_database_subnet_group" {
  description = "Create a database subnet group for RDS"
  type        = bool
  default     = false
}

variable "database_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "app_subnet_tags" {
  description = "Additional tags for app subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 support in the VPC"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on launch for public subnets"
  type        = bool
  default     = true
}
