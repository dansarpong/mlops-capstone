# AWS RDS Terraform Module

This module provisions AWS Relational Database Service (RDS) instances with support for various database engines, read replicas, parameter groups, option groups, and enhanced monitoring, following AWS best practices and the principle of separation of concerns.

## Features

- Creates RDS instances with configurable settings for various database engines (MySQL, PostgreSQL, MariaDB, Oracle, SQL Server)
- Supports both cross-region and same-region read replicas
- Creates DB subnet groups, parameter groups, and option groups
- Configures enhanced monitoring with external IAM roles
- Enables performance insights for database performance analysis
- Supports encryption with KMS keys
- Configures automated backups and maintenance windows
- Manages master user passwords in AWS Secrets Manager
- Highly customizable through variables

## Usage

### Basic MySQL Database

```terraform
module "mysql" {
  source = "./terraform/modules/rds"

  name        = "app"
  environment = "dev"

  # Engine options
  engine         = "mysql"
  engine_version = "8.0"

  # Instance configuration
  instance_class = "db.t3.small"

  # Storage
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Authentication
  db_name  = "appdb"
  username = "admin"
  password = "YourSecurePassword123!"

  # Network
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # Backup
  backup_retention_period = 7

  # Maintenance
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Tags
  tags = {
    Environment = "dev"
    Project     = "app"
  }
}
```

### PostgreSQL with Parameter Group and Enhanced Monitoring

```terraform
# First create an IAM role for RDS Enhanced Monitoring
module "rds_monitoring_role" {
  source = "./terraform/modules/iam"

  name = "rds-monitoring-role"

  # Role configuration
  trusted_role_services = ["monitoring.rds.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]

  tags = {
    Environment = "production"
    Project     = "api"
  }
}

# Then create the RDS instance with enhanced monitoring
module "postgres" {
  source = "./terraform/modules/rds"

  name        = "api"
  environment = "production"

  # Engine options
  engine         = "postgres"
  engine_version = "14.5"

  # Instance configuration
  instance_class    = "db.r5.large"
  multi_az          = true
  availability_zone = null

  # Storage
  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_encrypted     = true

  # Authentication
  db_name  = "apidb"
  username = "postgres"
  password = "YourSecurePassword123!"

  # Network
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # Parameter group
  create_db_parameter_group = true
  family                    = "postgres14"
  parameters = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "shared_buffers"
      value = "{DBInstanceClassMemory/32768}"
    }
  ]

  # Enhanced monitoring
  monitoring_interval = 30
  monitoring_role_arn = module.rds_monitoring_role.role_arn

  # Performance insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Backup
  backup_retention_period = 30
  copy_tags_to_snapshot   = true

  # Deletion protection
  deletion_protection = true

  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

### MySQL with Read Replica

```terraform
# Primary database
module "mysql_primary" {
  source = "./terraform/modules/rds"

  name        = "app-primary"
  environment = "production"

  # Engine options
  engine         = "mysql"
  engine_version = "8.0"

  # Instance configuration
  instance_class = "db.r5.large"
  multi_az       = true

  # Storage
  allocated_storage = 100
  storage_type      = "gp3"
  storage_encrypted = true

  # Authentication
  db_name  = "appdb"
  username = "admin"
  password = "YourSecurePassword123!"

  # Network
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]

  tags = {
    Environment = "production"
    Project     = "app"
  }
}

# Read replica
module "mysql_replica" {
  source = "./terraform/modules/rds"

  name        = "app-replica"
  environment = "production"

  # Replica configuration
  replicate_source_db = module.mysql_primary.db_instance_identifier

  # Instance configuration
  instance_class = "db.r5.large"

  # Network
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]

  tags = {
    Environment = "production"
    Project     = "app"
    Role        = "replica"
  }
}
```

### MySQL with Secrets Manager Password Management

```terraform
module "mysql_with_secrets" {
  source = "./terraform/modules/rds"

  name        = "app"
  environment = "dev"

  # Engine options
  engine         = "mysql"
  engine_version = "8.0"

  # Instance configuration
  instance_class = "db.t3.small"

  # Storage
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Authentication with Secrets Manager
  db_name                     = "appdb"
  username                    = "admin"
  manage_master_user_password = true

  # Network
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]

  tags = {
    Environment = "dev"
    Project     = "app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name prefix for all resources | string | n/a | yes |
| environment | Environment name (dev, staging, prod) | string | "dev" | no |
| identifier | The name of the RDS instance | string | null | no |
| replica_identifier | The name of the replica RDS instance | string | null | no |
| replicate_source_db | Specifies that this resource is a Replicate database, and to use this value as the source database | bool | false | no |
| source_db_instance_identifier | Identifier of the source DB instance for same-region replication | string | null | no |
| source_region | The source region for cross-region replication | string | null | no |
| engine | The database engine to use | string | "mysql" | no |
| engine_version | The engine version to use | string | "8.0" | no |
| auto_minor_version_upgrade | Indicates that minor engine upgrades will be applied automatically | bool | true | no |
| instance_class | The instance type of the RDS instance | string | "db.t3.small" | no |
| availability_zone | The AZ for the RDS instance | string | null | no |
| multi_az | Specifies if the RDS instance is multi-AZ | bool | false | no |
| allocated_storage | The allocated storage in gigabytes | number | 20 | no |
| max_allocated_storage | Upper limit to which Amazon RDS can automatically scale the storage | number | 0 | no |
| storage_type | One of 'standard', 'gp2', 'gp3', or 'io1' | string | "gp3" | no |
| iops | The amount of provisioned IOPS | number | null | no |
| storage_encrypted | Specifies whether the DB instance is encrypted | bool | true | no |
| kms_key_id | The ARN for the KMS encryption key | string | null | no |
| db_name | The name of the database to create | string | null | no |
| username | Username for the master DB user | string | "admin" | no |
| password | Password for the master DB user | string | n/a | yes |
| manage_master_user_password | Set to true to allow RDS to manage the master user password in Secrets Manager | bool | false | no |
| master_user_secret_kms_key_id | The KMS key ID to encrypt the master user password secret | string | null | no |
| vpc_security_group_ids | List of VPC security groups to associate | list(string) | [] | no |
| db_subnet_group_name | Name of DB subnet group | string | null | no |
| subnet_ids | A list of VPC subnet IDs | list(string) | [] | no |
| create_db_subnet_group | Whether to create a DB subnet group | bool | true | no |
| publicly_accessible | Bool to control if instance is publicly accessible | bool | false | no |
| port | The port on which the DB accepts connections | number | null | no |
| parameter_group_name | Name of the DB parameter group to associate | string | null | no |
| create_db_parameter_group | Whether to create a DB parameter group | bool | false | no |
| parameter_group_description | Description of the DB parameter group to create | string | "Managed by Terraform" | no |
| family | The family of the DB parameter group | string | null | no |
| parameters | A list of DB parameters to apply | list(map(string)) | [] | no |
| option_group_name | Name of the DB option group to associate | string | null | no |
| create_db_option_group | Whether to create a DB option group | bool | false | no |
| option_group_description | Description of the DB option group to create | string | "Managed by Terraform" | no |
| major_engine_version | Specifies the major version of the engine for the option group | string | null | no |
| options | A list of Options to apply | any | [] | no |
| backup_retention_period | The days to retain backups for | number | 7 | no |
| backup_window | The daily time range for automated backups | string | "03:00-06:00" | no |
| copy_tags_to_snapshot | Copy all instance tags to snapshots | bool | true | no |
| skip_final_snapshot | Determines whether a final DB snapshot is created before deletion | bool | true | no |
| final_snapshot_identifier_prefix | The name prefix for the final snapshot | string | "final" | no |
| snapshot_identifier | Specifies whether to create from a snapshot | string | null | no |
| maintenance_window | The window to perform maintenance in | string | "Mon:00:00-Mon:03:00" | no |
| apply_immediately | Specifies whether modifications are applied immediately | bool | false | no |
| monitoring_interval | The interval for Enhanced Monitoring metrics collection | number | 0 | no |
| monitoring_role_arn | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics | string | null | no |
| performance_insights_enabled | Specifies whether Performance Insights are enabled | bool | false | no |
| performance_insights_retention_period | The retention period for Performance Insights data | number | 7 | no |
| performance_insights_kms_key_id | The ARN for the KMS key to encrypt Performance Insights data | string | null | no |
| deletion_protection | The database can't be deleted when this value is set to true | bool | false | no |
| timeouts | Define maximum timeout for creating, updating, and deleting database resources | map(string) | { create = "60m", update = "60m", delete = "60m" } | no |
| tags | A mapping of tags to assign to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_address | The address of the RDS instance |
| db_instance_arn | The ARN of the RDS instance |
| db_instance_endpoint | The connection endpoint of the RDS instance |
| db_instance_id | The RDS instance ID |
| db_instance_identifier | The RDS instance identifier |
| db_instance_name | The database name |
| db_instance_username | The master username for the database |
| db_instance_port | The database port |
| db_instance_ca_cert_identifier | Specifies the identifier of the CA certificate for the DB instance |
| db_instance_master_user_secret_arn | The ARN of the master user secret |
| db_subnet_group_id | The db subnet group name |
| db_subnet_group_arn | The ARN of the db subnet group |
| db_parameter_group_id | The db parameter group name |
| db_parameter_group_arn | The ARN of the db parameter group |
| db_option_group_id | The db option group name |
| db_option_group_arn | The ARN of the db option group |
| enhanced_monitoring_iam_role_name | The name of the enhanced monitoring role |
| enhanced_monitoring_iam_role_arn | The ARN of the enhanced monitoring role |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- VPC with subnets (from a VPC module)
- Security groups (from a security-group module)
- IAM role for enhanced monitoring (from an IAM module) if needed

## Notes

- This module follows the principle of separation of concerns by accepting external resources as inputs rather than creating them internally
- For production environments, it's recommended to enable multi-AZ deployment for high availability
- Use parameter groups to customize database settings according to your workload
- Enable enhanced monitoring and performance insights for better visibility into database performance
- Always encrypt your database instances in production environments
- Use read replicas to scale read operations and for disaster recovery
- Set appropriate backup retention periods based on your data recovery requirements
- Consider using option groups for additional database engine features
- Security groups should be created using a dedicated security-group module
- For enhanced security, use the `manage_master_user_password` feature to let AWS Secrets Manager handle password rotation
- When using enhanced monitoring, create an IAM role with the appropriate permissions using a dedicated IAM module
- For production workloads, set `deletion_protection = true` to prevent accidental database deletion
- Use `max_allocated_storage` to enable storage autoscaling for databases with variable storage needs
