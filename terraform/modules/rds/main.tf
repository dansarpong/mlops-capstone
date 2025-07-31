# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = local.subnet_group_name
  description = "Database subnet group for ${local.db_identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = local.subnet_group_name
    }
  )
}

# DB Parameter Group
resource "aws_db_parameter_group" "this" {
  count = var.create_db_parameter_group ? 1 : 0

  name        = local.parameter_group_name
  description = var.parameter_group_description
  family      = var.family != null ? var.family : local.default_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.parameter_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DB Option Group
resource "aws_db_option_group" "this" {
  count = var.create_db_option_group ? 1 : 0

  name                     = local.option_group_name
  option_group_description = var.option_group_description
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version != null ? var.major_engine_version : local.default_option_group_major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name                    = option.value.option_name
      port                           = lookup(option.value, "port", null)
      version                        = lookup(option.value, "version", null)
      db_security_group_memberships  = lookup(option.value, "db_security_group_memberships", null)
      vpc_security_group_memberships = lookup(option.value, "vpc_security_group_memberships", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.option_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Primary DB Instance
resource "aws_db_instance" "this" {
  count = local.is_primary ? 1 : 0

  identifier     = local.db_identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Authentication
  db_name  = var.db_name
  username = var.username
  password = var.password

  # Network
  port                   = var.port
  multi_az               = var.multi_az
  availability_zone      = var.availability_zone
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  publicly_accessible    = var.publicly_accessible

  # Database options
  parameter_group_name = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_db_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${local.db_identifier}-${replace(timestamp(), ":", "-")}"
  snapshot_identifier       = var.snapshot_identifier

  # Maintenance
  maintenance_window         = var.maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  # Deletion Protection
  deletion_protection = var.deletion_protection

  # Manage master user password in Secrets Manager
  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name = local.db_identifier
    }
  )

  timeouts {
    create = lookup(var.timeouts, "create", "60m")
    update = lookup(var.timeouts, "update", "60m")
    delete = lookup(var.timeouts, "delete", "60m")
  }

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}

# Cross-Region Read Replica
resource "aws_db_instance" "replica" {
  count = local.is_cross_region_replica || local.is_same_region_replica ? 1 : 0

  identifier     = local.replica_identifier
  instance_class = var.instance_class

  # Replica Source
  replicate_source_db = var.replicate_source_db != false ? var.replicate_source_db : var.source_db_instance_identifier

  # Storage
  storage_type      = var.storage_type
  iops              = var.iops
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # Network
  port                   = var.port
  multi_az               = var.multi_az
  availability_zone      = var.availability_zone
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  publicly_accessible    = var.publicly_accessible

  # Database options
  parameter_group_name = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_db_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${local.replica_identifier}-${replace(timestamp(), ":", "-")}"

  # Maintenance
  maintenance_window         = var.maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  # Deletion Protection
  deletion_protection = var.deletion_protection

  tags = merge(
    var.tags,
    {
      Name = local.replica_identifier
    }
  )

  timeouts {
    create = lookup(var.timeouts, "create", "60m")
    update = lookup(var.timeouts, "update", "60m")
    delete = lookup(var.timeouts, "delete", "60m")
  }

  lifecycle {
    ignore_changes = [
      replicate_source_db
    ]
  }
}
