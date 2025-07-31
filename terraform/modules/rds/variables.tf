# General
variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
  default     = null
}

variable "replica_identifier" {
  description = "The name of the replica RDS instance"
  type        = string
  default     = null
}

# Replica Configuration
variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate"
  type        = bool
  default     = false
}

variable "source_db_instance_identifier" {
  description = "Identifier of the source DB instance for same-region replication"
  type        = string
  default     = null
}

variable "source_region" {
  description = "The source region for cross-region replication"
  type        = string
  default     = null
}

# Engine Options
variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "mysql"
  validation {
    condition     = contains(["mysql", "postgres", "mariadb", "oracle-ee", "oracle-se2", "oracle-se1", "oracle-se", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"], var.engine)
    error_message = "Valid values for engine are (mysql, postgres, mariadb, oracle-ee, oracle-se2, oracle-se1, oracle-se, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web)."
  }
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "8.0"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

# Instance Configuration
variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "availability_zone" {
  description = "The AZ for the RDS instance"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

# Storage
variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1"], var.storage_type)
    error_message = "Valid values for storage_type are (standard, gp2, gp3, io1)."
  }
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' or 'gp3'"
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN"
  type        = string
  default     = null
}

# Authentication
variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = null
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Password for the master DB user"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

variable "master_user_secret_kms_key_id" {
  description = "The KMS key ID to encrypt the master user password secret in Secrets Manager"
  type        = string
  default     = null
}

# Network
variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
  default     = []
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. If not specified, it will create a new one"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs to create a new DB subnet group"
  type        = list(string)
  default     = []
}

variable "create_db_subnet_group" {
  description = "Whether to create a DB subnet group"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}

# Database Options
variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = null
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate"
  type        = string
  default     = null
}

variable "create_db_parameter_group" {
  description = "Whether to create a DB parameter group"
  type        = bool
  default     = false
}

variable "parameter_group_description" {
  description = "Description of the DB parameter group to create"
  type        = string
  default     = "Managed by Terraform"
}

variable "family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null
}

variable "parameters" {
  description = "A list of DB parameters to apply"
  type        = list(map(string))
  default     = []
}

variable "option_group_name" {
  description = "Name of the DB option group to associate"
  type        = string
  default     = null
}

variable "create_db_option_group" {
  description = "Whether to create a DB option group"
  type        = bool
  default     = false
}

variable "option_group_description" {
  description = "Description of the DB option group to create"
  type        = string
  default     = "Managed by Terraform"
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "options" {
  description = "A list of Options to apply"
  type        = any
  default     = []
}

# Backup
variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled"
  type        = string
  default     = "03:00-06:00"
}

variable "copy_tags_to_snapshot" {
  description = "Copy all instance tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier_prefix" {
  description = "The name which is prefixed to the final snapshot on cluster destroy"
  type        = string
  default     = "final"
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot"
  type        = string
  default     = null
}

# Maintenance
variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

# Enhanced Monitoring
variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
  default     = null
}

# Performance Insights
variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

# Deletion Protection
variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = false
}

# Timeouts
variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting database resources"
  type        = map(string)
  default = {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# Tags
variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
