# CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "this" {
  count = var.create_metric_alarms && var.metric_name != null && var.namespace != null ? 1 : 0

  alarm_name          = "${local.alarm_name_prefix}${var.name}"
  alarm_description   = var.alarm_description
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  actions_enabled     = var.actions_enabled
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions
  unit                = var.unit
  dimensions          = var.dimensions
  treat_missing_data  = var.treat_missing_data

  tags = merge(
    var.tags,
    {
      Name = "${local.alarm_name_prefix}${var.name}"
    }
  )
}

# Additional Metric Alarms
resource "aws_cloudwatch_metric_alarm" "additional" {
  for_each = var.create_metric_alarms ? var.metric_alarms : {}

  alarm_name          = lookup(each.value, "alarm_name", "${local.alarm_name_prefix}${var.name}-${each.key}")
  alarm_description   = lookup(each.value, "alarm_description", var.alarm_description)
  comparison_operator = lookup(each.value, "comparison_operator", var.comparison_operator)
  evaluation_periods  = lookup(each.value, "evaluation_periods", var.evaluation_periods)
  threshold           = lookup(each.value, "threshold", var.threshold)
  metric_name         = lookup(each.value, "metric_name", null)
  namespace           = lookup(each.value, "namespace", null)
  period              = lookup(each.value, "period", var.period)
  statistic           = lookup(each.value, "statistic", var.statistic)
  actions_enabled     = lookup(each.value, "actions_enabled", var.actions_enabled)
  alarm_actions       = lookup(each.value, "alarm_actions", var.alarm_actions)
  ok_actions          = lookup(each.value, "ok_actions", var.ok_actions)
  insufficient_data_actions = lookup(each.value, "insufficient_data_actions", var.insufficient_data_actions)
  unit                = lookup(each.value, "unit", var.unit)
  dimensions          = lookup(each.value, "dimensions", var.dimensions)
  treat_missing_data  = lookup(each.value, "treat_missing_data", var.treat_missing_data)

  dynamic "metric_query" {
    for_each = lookup(each.value, "metric_query", [])
    content {
      id          = lookup(metric_query.value, "id", null)
      expression  = lookup(metric_query.value, "expression", null)
      label       = lookup(metric_query.value, "label", null)
      return_data = lookup(metric_query.value, "return_data", null)

      dynamic "metric" {
        for_each = lookup(metric_query.value, "metric", [])
        content {
          metric_name = lookup(metric.value, "metric_name", null)
          namespace   = lookup(metric.value, "namespace", null)
          period      = lookup(metric.value, "period", null)
          stat        = lookup(metric.value, "stat", null)
          unit        = lookup(metric.value, "unit", null)
          dimensions  = lookup(metric.value, "dimensions", null)
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = lookup(each.value, "alarm_name", "${local.alarm_name_prefix}${var.name}-${each.key}")
    },
    lookup(each.value, "tags", {})
  )
}

# CloudWatch Composite Alarms
resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = var.create_composite_alarms ? var.composite_alarms : {}

  alarm_name          = lookup(each.value, "alarm_name", "${local.alarm_name_prefix}${var.name}-composite-${each.key}")
  alarm_description   = lookup(each.value, "alarm_description", var.alarm_description)
  alarm_rule          = each.value.alarm_rule
  actions_enabled     = lookup(each.value, "actions_enabled", var.actions_enabled)
  alarm_actions       = lookup(each.value, "alarm_actions", var.alarm_actions)
  ok_actions          = lookup(each.value, "ok_actions", var.ok_actions)
  insufficient_data_actions = lookup(each.value, "insufficient_data_actions", var.insufficient_data_actions)

  tags = merge(
    var.tags,
    {
      Name = lookup(each.value, "alarm_name", "${local.alarm_name_prefix}${var.name}-composite-${each.key}")
    },
    lookup(each.value, "tags", {})
  )
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_dashboard && var.dashboard_body != null ? 1 : 0

  dashboard_name = local.dashboard_name
  dashboard_body = var.dashboard_body
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key_id

  tags = merge(
    var.tags,
    {
      Name = local.log_group_name
    }
  )
}

# CloudWatch Metric Filters
resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = var.create_metric_filters && var.create_log_group ? var.metric_filters : {}

  name           = lookup(each.value, "name", "${local.alarm_name_prefix}${var.name}-filter-${each.key}")
  pattern        = each.value.pattern
  log_group_name = aws_cloudwatch_log_group.this[0].name

  metric_transformation {
    name      = lookup(each.value, "metric_transformation_name", "${local.alarm_name_prefix}${var.name}-metric-${each.key}")
    namespace = lookup(each.value, "metric_transformation_namespace", "CustomMetrics/${var.name}")
    value     = lookup(each.value, "metric_transformation_value", "1")
    unit      = lookup(each.value, "metric_transformation_unit", null)
    dimensions = lookup(each.value, "metric_transformation_dimensions", null)
  }
}
