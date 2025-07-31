
locals {

  # Use provided name or generate one
  db_identifier = var.identifier != null ? var.identifier : "${var.name}-${var.environment}"

  # Use provided name or generate one for replica
  replica_identifier = var.replica_identifier != null ? var.replica_identifier : "${local.db_identifier}-replica"

  # Use provided name or generate one for subnet group
  subnet_group_name = var.create_db_subnet_group ? (
    var.db_subnet_group_name != null ? var.db_subnet_group_name : "${local.db_identifier}-subnet-group"
  ) : var.db_subnet_group_name

  # Use provided name or generate one for parameter group
  parameter_group_name = var.create_db_parameter_group ? (
    var.parameter_group_name != null ? var.parameter_group_name : "${local.db_identifier}-parameter-group"
  ) : var.parameter_group_name

  # Use provided name or generate one for option group
  option_group_name = var.create_db_option_group ? (
    var.option_group_name != null ? var.option_group_name : "${local.db_identifier}-option-group"
  ) : var.option_group_name

  # Determine if this is a primary instance or a replica
  is_primary = !var.replicate_source_db && var.source_db_instance_identifier == null

  # Determine if this is a cross-region replica
  is_cross_region_replica = var.replicate_source_db && var.source_db_instance_identifier == null

  # Determine if this is a same-region replica
  is_same_region_replica = !var.replicate_source_db && var.source_db_instance_identifier != null

  # Default parameter group family if none provided
  default_family = "${var.engine}${regex("^\\d+\\.\\d+", var.engine_version)}"

  # Default option group engine name
  default_option_group_engine = var.engine == "mariadb" ? "mysql" : var.engine

  # Default option group major engine version
  default_option_group_major_engine_version = regex("^\\d+\\.\\d+", var.engine_version)
}
