output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "app_subnet_ids" {
  description = "List of app subnet IDs"
  value       = aws_subnet.app[*].id
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "app_subnet_cidrs" {
  description = "List of app subnet CIDR blocks"
  value       = aws_subnet.app[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = aws_subnet.database[*].cidr_block
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = aws_subnet.private[*].arn
}

output "app_subnet_arns" {
  description = "List of app subnet ARNs"
  value       = aws_subnet.app[*].arn
}

output "database_subnet_arns" {
  description = "List of database subnet ARNs"
  value       = aws_subnet.database[*].arn
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "app_route_table_id" {
  description = "ID of the app route table"
  value       = length(aws_route_table.app) > 0 ? aws_route_table.app[0].id : null
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = length(aws_route_table.database) > 0 ? aws_route_table.database[0].id : null
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IP addresses of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}

output "azs" {
  description = "List of availability zones used (alias for availability_zones)"
  value       = local.availability_zones
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC (alias for vpc_cidr)"
  value       = aws_vpc.this.cidr_block
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled in the VPC"
  value       = aws_vpc.this.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled in the VPC"
  value       = aws_vpc.this.enable_dns_hostnames
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = aws_vpc.this.default_route_table_id
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = aws_vpc.this.main_route_table_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.this.arn
}
