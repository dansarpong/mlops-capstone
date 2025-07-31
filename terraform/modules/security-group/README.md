# AWS Security Group Terraform Module

This module provisions AWS Security Groups with ingress and egress rules, following AWS best practices and the principle of separation of concerns.

## Features

- Creates security groups with customizable rules
- Supports various rule types (CIDR blocks, security group references, self-references, prefix lists)
- Implements security group referencing for complex networking setups
- Supports both IPv4 and IPv6 rules
- Highly customizable through variables

## Usage

### Basic Usage

```terraform
module "web_sg" {
  source = "./terraform/modules/security-group"

  name   = "web-server"
  vpc_id = module.vpc.vpc_id
  
  # Use default settings (allow all outbound traffic)
}
```

### Web Server Security Group

```terraform
module "web_sg" {
  source = "./terraform/modules/security-group"

  name        = "web-server"
  vpc_id      = module.vpc.vpc_id
  
  # Ingress rules with CIDR blocks
  ingress_with_cidr_blocks = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from internal network"
      cidr_blocks = "10.0.0.0/8"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Database Security Group with References

```terraform
module "db_sg" {
  source = "./terraform/modules/security-group"

  name        = "database"
  vpc_id      = module.vpc.vpc_id
  
  # Ingress rules with source security group ID
  ingress_with_source_security_group_id = {
    mysql = {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL from web servers"
      source_security_group_id = module.web_sg.security_group_id
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Complex Security Group with Multiple Rule Types

```terraform
module "app_sg" {
  source = "./terraform/modules/security-group"

  name        = "application"
  vpc_id      = module.vpc.vpc_id
  
  # Ingress rules with CIDR blocks
  ingress_with_cidr_blocks = {
    http = {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "HTTP from internal network"
      cidr_blocks = "10.0.0.0/8"
    }
  }
  
  # Ingress rules with source security group ID
  ingress_with_source_security_group_id = {
    all = {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "All TCP from load balancer"
      source_security_group_id = module.lb_sg.security_group_id
    }
  }
  
  # Ingress rules with self
  ingress_with_self = {
    all = {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "All TCP from self"
    }
  }
  
  # Egress rules with CIDR blocks
  egress_with_cidr_blocks = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP to internet"
      cidr_blocks = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS to internet"
      cidr_blocks = "0.0.0.0/0"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "application"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the security group | string | n/a | yes |
| name_prefix | Prefix to add to the security group name | string | null | no |
| description | Description of the security group | string | "Security group managed by Terraform" | no |
| vpc_id | ID of the VPC where to create security group | string | n/a | yes |
| revoke_rules_on_delete | Instruct Terraform to revoke all of the Security Group's attached ingress and egress rules before deleting the security group itself | bool | false | no |
| ingress_with_cidr_blocks | Map of ingress rules to create with cidr_blocks | map(any) | {} | no |
| ingress_with_source_security_group_id | Map of ingress rules to create with source_security_group_id | map(any) | {} | no |
| ingress_with_self | Map of ingress rules to create with self | map(any) | {} | no |
| ingress_with_prefix_list_ids | Map of ingress rules to create with prefix_list_ids | map(any) | {} | no |
| egress_with_cidr_blocks | Map of egress rules to create with cidr_blocks | map(any) | {} | no |
| egress_with_source_security_group_id | Map of egress rules to create with source_security_group_id | map(any) | {} | no |
| egress_with_self | Map of egress rules to create with self | map(any) | {} | no |
| egress_with_prefix_list_ids | Map of egress rules to create with prefix_list_ids | map(any) | {} | no |
| create_default_egress_rule | Whether to create default egress rule (allow all outbound traffic) | bool | true | no |
| timeouts | Define maximum timeout for creating, updating, and deleting security group resources | map(string) | {} | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | The ID of the security group |
| security_group_arn | The ARN of the security group |
| security_group_vpc_id | The VPC ID of the security group |
| security_group_name | The name of the security group |
| security_group_description | The description of the security group |
| security_group_owner_id | The owner ID of the security group |
| ingress_with_cidr_blocks_security_group_rule_ids | IDs of the ingress security group rules with CIDR blocks |
| ingress_with_source_security_group_id_security_group_rule_ids | IDs of the ingress security group rules with source security group ID |
| ingress_with_self_security_group_rule_ids | IDs of the ingress security group rules with self |
| ingress_with_prefix_list_ids_security_group_rule_ids | IDs of the ingress security group rules with prefix list IDs |
| egress_with_cidr_blocks_security_group_rule_ids | IDs of the egress security group rules with CIDR blocks |
| egress_with_source_security_group_id_security_group_rule_ids | IDs of the egress security group rules with source security group ID |
| egress_with_self_security_group_rule_ids | IDs of the egress security group rules with self |
| egress_with_prefix_list_ids_security_group_rule_ids | IDs of the egress security group rules with prefix list IDs |
| default_egress_security_group_rule_id | ID of the default egress security group rule |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- VPC (from a VPC module)

## Notes

- This module follows the principle of separation of concerns by focusing only on security group resources
- For production environments, it's recommended to restrict ingress rules to specific CIDR blocks
- Use security group references instead of CIDR blocks for internal communication
- The module creates a default "allow all outbound traffic" rule if no egress rules are provided
- Security groups are stateful, so return traffic is automatically allowed
