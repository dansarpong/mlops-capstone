# CloudWatch Metric Alarm Outputs
output "metric_alarm_id" {
  description = "The ID of the default metric alarm"
  value       = try(aws_cloudwatch_metric_alarm.this[0].id, null)
}

output "metric_alarm_arn" {
  description = "The ARN of the default metric alarm"
  value       = try(aws_cloudwatch_metric_alarm.this[0].arn, null)
}

output "metric_alarm_name" {
  description = "The name of the default metric alarm"
  value       = try(aws_cloudwatch_metric_alarm.this[0].alarm_name, null)
}

output "additional_metric_alarm_ids" {
  description = "Map of IDs of the additional metric alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.additional : k => v.id }
}

output "additional_metric_alarm_arns" {
  description = "Map of ARNs of the additional metric alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.additional : k => v.arn }
}

output "additional_metric_alarm_names" {
  description = "Map of names of the additional metric alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.additional : k => v.alarm_name }
}

# CloudWatch Composite Alarm Outputs
output "composite_alarm_ids" {
  description = "Map of IDs of the composite alarms"
  value       = { for k, v in aws_cloudwatch_composite_alarm.this : k => v.id }
}

output "composite_alarm_arns" {
  description = "Map of ARNs of the composite alarms"
  value       = { for k, v in aws_cloudwatch_composite_alarm.this : k => v.arn }
}

output "composite_alarm_names" {
  description = "Map of names of the composite alarms"
  value       = { for k, v in aws_cloudwatch_composite_alarm.this : k => v.alarm_name }
}

# CloudWatch Dashboard Outputs
output "dashboard_arn" {
  description = "The ARN of the dashboard"
  value       = try(aws_cloudwatch_dashboard.this[0].dashboard_arn, null)
}

output "dashboard_name" {
  description = "The name of the dashboard"
  value       = try(aws_cloudwatch_dashboard.this[0].dashboard_name, null)
}

# CloudWatch Log Group Outputs
output "log_group_arn" {
  description = "The ARN of the log group"
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

output "log_group_name" {
  description = "The name of the log group"
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

# CloudWatch Metric Filter Outputs
output "metric_filter_ids" {
  description = "Map of IDs of the metric filters"
  value       = { for k, v in aws_cloudwatch_log_metric_filter.this : k => v.id }
}

output "metric_filter_names" {
  description = "Map of names of the metric filters"
  value       = { for k, v in aws_cloudwatch_log_metric_filter.this : k => v.name }
}
