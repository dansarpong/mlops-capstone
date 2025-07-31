
# AWS VPC Terraform Module

This module creates a VPC with configurable public, private, app, and database subnets across multiple availability zones.

## Features

- **Flexible subnet configuration**: Support for public, private, app, and database subnets
- **Multiple AZ support**: Distribute subnets across 2-6 availability zones
- **Custom or automatic CIDR calculation**: Specify individual subnet CIDRs or use automatic calculation
- **NAT Gateway options**: Single NAT Gateway for cost optimization or per-AZ NAT Gateways for high availability
- **Database subnet group**: Optional RDS database subnet group creation
- **Comprehensive tagging**: Support for default and subnet-specific tags (per subnet type)
- **IPv6 support**: Optional IPv6 CIDR block assignment
- **DNS and public IP options**: Enable/disable DNS hostnames, DNS support, and public IP assignment

## Usage

### Basic Usage

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name     = "example"
  vpc_cidr = "10.0.0.0/16"

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}
```

### Advanced Usage (with all subnet types)

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name                   = "production"
  vpc_cidr               = "10.0.0.0/16"
  public_subnets_cidr    = "10.0.0.0/20"
  private_subnets_cidr   = "10.0.16.0/20"
  app_subnets_cidr       = "10.0.32.0/20"
  database_subnets_cidr  = "10.0.64.0/20"
  az_count               = 3
  create_subnet_types    = ["public", "private", "app", "database"]
  single_nat_gateway     = false  # Use one NAT Gateway per AZ for high availability
  subnet_newbits         = 2      # Divide each subnet CIDR into 4 (2^2) equal parts
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_ipv6            = false
  map_public_ip_on_launch = true

  tags = {
    Environment = "production"
    Project     = "example"
    Terraform   = "true"
  }
}
```

### Cost-Saving Configuration

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name               = "staging"
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 2
  single_nat_gateway = true  # Use a single NAT Gateway for cost savings

  tags = {
    Environment = "staging"
  }
}
```

### Disable NAT Gateways

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name              = "dev"
  vpc_cidr          = "10.0.0.0/16"
  enable_nat_gateway = false  # Disable NAT Gateways completely

  tags = {
    Environment = "dev"
  }
}
```

### Selective Subnet Creation

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name               = "public-only"
  vpc_cidr           = "10.0.0.0/16"

  create_subnet_types = ["public"]  # Create only public subnets
  enable_nat_gateway  = false       # No need for NAT Gateways

  tags = {
    Environment = "demo"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name prefix for all resources | string | "main" | no |
| vpc_cidr | CIDR block for the VPC | string | "10.0.0.0/16" | no |
| public_subnets_cidr | CIDR block for public subnets (used if public_subnet_cidrs is empty) | string | "10.0.0.0/20" | no |
| private_subnets_cidr | CIDR block for private subnets (used if private_subnet_cidrs is empty) | string | "10.0.16.0/20" | no |
| app_subnets_cidr | CIDR block for app subnets (used if app_subnet_cidrs is empty) | string | "10.0.32.0/20" | no |
| database_subnets_cidr | CIDR block for database subnets (used if database_subnet_cidrs is empty) | string | "10.0.64.0/20" | no |
| public_subnet_cidrs | List of specific CIDR blocks for public subnets | list(string) | [] | no |
| private_subnet_cidrs | List of specific CIDR blocks for private subnets | list(string) | [] | no |
| app_subnet_cidrs | List of specific CIDR blocks for app subnets | list(string) | [] | no |
| database_subnet_cidrs | List of specific CIDR blocks for database subnets | list(string) | [] | no |
| az_count | Number of availability zones to use (2-6) | number | 2 | no |
| availability_zones | List of availability zones to use (overrides az_count if set) | list(string) | [] | no |
| subnet_newbits | Number of additional bits to extend the subnet CIDR | number | 2 | no |
| single_nat_gateway | Use a single NAT gateway for all private subnets (cost savings) | bool | false | no |
| enable_nat_gateway | Enable NAT gateway for private subnets | bool | true | no |
| create_subnet_types | List of subnet types to create (valid: public, private, app, database) | list(string) | ["public", "private"] | no |
| create_database_subnet_group | Create a database subnet group for RDS | bool | false | no |
| database_subnet_group_name | Name of the database subnet group | string | "" | no |
| tags | Tags to apply to all resources | map(string) | {} | no |
| public_subnet_tags | Additional tags for public subnets | map(string) | {} | no |
| private_subnet_tags | Additional tags for private subnets | map(string) | {} | no |
| app_subnet_tags | Additional tags for app subnets | map(string) | {} | no |
| database_subnet_tags | Additional tags for database subnets | map(string) | {} | no |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | bool | true | no |
| enable_dns_support | Enable DNS support in the VPC | bool | true | no |
| enable_ipv6 | Enable IPv6 support in the VPC | bool | false | no |
| map_public_ip_on_launch | Map public IP on launch for public subnets | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr | The CIDR block of the VPC |
| vpc_cidr_block | The CIDR block of the VPC (alias) |
| vpc_enable_dns_support | Whether DNS support is enabled in the VPC |
| vpc_enable_dns_hostnames | Whether DNS hostnames are enabled in the VPC |
| vpc_default_security_group_id | The ID of the default security group |
| vpc_default_network_acl_id | The ID of the default network ACL |
| vpc_default_route_table_id | The ID of the default route table |
| vpc_main_route_table_id | The ID of the main route table associated with this VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| app_subnet_ids | List of app subnet IDs |
| database_subnet_ids | List of database subnet IDs |
| public_subnet_arns | List of public subnet ARNs |
| private_subnet_arns | List of private subnet ARNs |
| app_subnet_arns | List of app subnet ARNs |
| database_subnet_arns | List of database subnet ARNs |
| public_subnet_cidrs | List of public subnet CIDR blocks |
| private_subnet_cidrs | List of private subnet CIDR blocks |
| app_subnet_cidrs | List of app subnet CIDR blocks |
| database_subnet_cidrs | List of database subnet CIDR blocks |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | List of private route table IDs |
| app_route_table_id | ID of the app route table |
| database_route_table_id | ID of the database route table |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | List of public IP addresses of NAT Gateways |
| internet_gateway_id | ID of the Internet Gateway |
| internet_gateway_arn | ARN of the Internet Gateway |
| availability_zones | List of availability zones used |
| azs | List of availability zones used (alias) |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later

## Notes

- NAT Gateways are relatively expensive resources. Using `single_nat_gateway = true` can significantly reduce costs for non-production environments.
- For development environments or when NAT Gateways are not needed, set `enable_nat_gateway = false` to completely disable NAT Gateway provisioning.
- When creating only public subnets (`create_subnet_types = ["public"]`), NAT Gateways are not required and can be disabled.
- The module automatically selects available availability zones in the specified region if `availability_zones` is not set.
- You can create any combination of subnet types: `public`, `private`, `app`, and `database`.
- Subnet-specific tags can be set for each subnet type using the corresponding `*_subnet_tags` variable.
- IPv6, DNS hostnames, and DNS support can be enabled/disabled via input variables.
