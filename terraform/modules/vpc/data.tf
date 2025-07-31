data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for subnet configuration
locals {
  # Use custom AZs if provided, otherwise use the first az_count available zones
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Calculate subnet CIDRs if not provided
  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for i in range(var.az_count) : cidrsubnet(var.public_subnets_cidr, var.subnet_newbits, i)
  ]

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for i in range(var.az_count) : cidrsubnet(var.private_subnets_cidr, var.subnet_newbits, i)
  ]

  app_subnet_cidrs = length(var.app_subnet_cidrs) > 0 ? var.app_subnet_cidrs : [
    for i in range(var.az_count) : cidrsubnet(var.app_subnets_cidr, var.subnet_newbits, i)
  ]

  database_subnet_cidrs = length(var.database_subnet_cidrs) > 0 ? var.database_subnet_cidrs : [
    for i in range(var.az_count) : cidrsubnet(var.database_subnets_cidr, var.subnet_newbits, i)
  ]

  # Validation: ensure we have enough CIDRs for the number of AZs
  public_subnet_count   = contains(var.create_subnet_types, "public") ? var.az_count : 0
  private_subnet_count  = contains(var.create_subnet_types, "private") ? var.az_count : 0
  app_subnet_count      = contains(var.create_subnet_types, "app") ? var.az_count : 0
  database_subnet_count = contains(var.create_subnet_types, "database") ? var.az_count : 0
}
