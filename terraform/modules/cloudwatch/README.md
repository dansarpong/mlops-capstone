# AWS CloudWatch Terraform Module

This module provisions AWS CloudWatch resources including alarms, dashboards, log groups, and metric filters, following AWS best practices and the principle of separation of concerns.

## Features

- Creates CloudWatch metric alarms with configurable settings
- Supports composite alarms for complex monitoring scenarios
- Provisions CloudWatch dashboards for visualization
- Creates log groups with configurable retention periods
- Sets up metric filters for log-based metrics
- Accepts external resources as input variables rather than creating them internally
- Highly customizable through variables

## Usage

### Basic Usage - Simple Metric Alarm

```terraform
module "cloudwatch" {
  source = "./terraform/modules/cloudwatch"

  name = "cpu-utilization"
  
  # Metric Alarm Configuration
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Average"
  threshold           = 80
  
  # Dimensions for the metric
  dimensions = {
    InstanceId = "i-12345678"
  }
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Multiple Metric Alarms

```terraform
module "cloudwatch" {
  source = "./terraform/modules/cloudwatch"

  name = "web-monitoring"
  
  # Create multiple metric alarms
  metric_alarms = {
    cpu = {
      alarm_name          = "high-cpu-utilization"
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      dimensions = {
        InstanceId = "i-12345678"
      }
    },
    memory = {
      alarm_name          = "high-memory-utilization"
      metric_name         = "MemoryUtilization"
      namespace           = "CWAgent"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      dimensions = {
        InstanceId = "i-12345678"
      }
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Composite Alarm

```terraform
module "cloudwatch" {
  source = "./terraform/modules/cloudwatch"

  name = "web-monitoring"
  
  # Create metric alarms
  metric_alarms = {
    cpu = {
      alarm_name          = "high-cpu-utilization"
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      dimensions = {
        InstanceId = "i-12345678"
      }
    },
    memory = {
      alarm_name          = "high-memory-utilization"
      metric_name         = "MemoryUtilization"
      namespace           = "CWAgent"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      period              = 300
      statistic           = "Average"
      threshold           = 80
      dimensions = {
        InstanceId = "i-12345678"
      }
    }
  }
  
  # Create composite alarm
  create_composite_alarms = true
  composite_alarms = {
    web_server = {
      alarm_name        = "web-server-critical"
      alarm_description = "Alarm when either CPU or Memory is high"
      alarm_rule        = "ALARM(${module.cloudwatch.additional_metric_alarm_arns["cpu"]}) OR ALARM(${module.cloudwatch.additional_metric_alarm_arns["memory"]})"
      alarm_actions     = ["arn:aws:sns:us-east-1:123456789012:alert-topic"]
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Dashboard, Log Group, and Metric Filter

```terraform
module "cloudwatch" {
  source = "./terraform/modules/cloudwatch"

  name = "application-monitoring"
  
  # Create CloudWatch Dashboard
  create_dashboard = true
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-12345678"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "EC2 Instance CPU"
        }
      }
    ]
  })
  
  # Create Log Group
  create_log_group = true
  log_group_retention_in_days = 30
  
  # Create Metric Filters
  create_metric_filters = true
  metric_filters = {
    error_count = {
      pattern = "ERROR"
      metric_transformation_name      = "ErrorCount"
      metric_transformation_namespace = "CustomMetrics/Application"
      metric_transformation_value     = "1"
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
| name | Name to be used for resources created by this module | string | n/a | yes |
| name_prefix | Prefix to add to the resource names | string | null | no |
| tags | Tags to apply to all resources | map(string) | {} | no |
| create_metric_alarms | Controls if CloudWatch metric alarms should be created | bool | true | no |
| metric_alarms | Map of metric alarm configurations to create | any | {} | no |
| alarm_description | The description for the alarm | string | "Managed by Terraform" | no |
| comparison_operator | The arithmetic operation to use when comparing the specified statistic and threshold | string | "GreaterThanOrEqualToThreshold" | no |
| evaluation_periods | The number of periods over which data is compared to the specified threshold | number | 1 | no |
| threshold | The value against which the specified statistic is compared | number | 0 | no |
| metric_name | The name for the alarm's associated metric | string | null | no |
| namespace | The namespace for the alarm's associated metric | string | null | no |
| period | The period in seconds over which the specified statistic is applied | number | 60 | no |
| statistic | The statistic to apply to the alarm's associated metric | string | "Average" | no |
| actions_enabled | Indicates whether or not actions should be executed during any changes to the alarm's state | bool | true | no |
| alarm_actions | The list of actions to execute when this alarm transitions into an ALARM state | list(string) | [] | no |
| insufficient_data_actions | The list of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state | list(string) | [] | no |
| ok_actions | The list of actions to execute when this alarm transitions into an OK state | list(string) | [] | no |
| unit | The unit for the alarm's associated metric | string | null | no |
| dimensions | The dimensions for the alarm's associated metric | map(string) | {} | no |
| treat_missing_data | How the alarm handles missing data points | string | "missing" | no |
| create_composite_alarms | Controls if CloudWatch composite alarms should be created | bool | false | no |
| composite_alarms | Map of composite alarm configurations to create | any | {} | no |
| create_dashboard | Controls if CloudWatch dashboard should be created | bool | false | no |
| dashboard_name | Name of the dashboard | string | null | no |
| dashboard_body | The JSON body of the dashboard | string | null | no |
| create_log_group | Controls if CloudWatch log group should be created | bool | false | no |
| log_group_name | Name of the log group | string | null | no |
| log_group_retention_in_days | Specifies the number of days you want to retain log events in the log group | number | 30 | no |
| log_group_kms_key_id | The ARN of the KMS Key to use when encrypting log data | string | null | no |
| create_metric_filters | Controls if CloudWatch metric filters should be created | bool | false | no |
| metric_filters | Map of metric filter configurations to create | any | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| metric_alarm_id | The ID of the default metric alarm |
| metric_alarm_arn | The ARN of the default metric alarm |
| metric_alarm_name | The name of the default metric alarm |
| additional_metric_alarm_ids | Map of IDs of the additional metric alarms |
| additional_metric_alarm_arns | Map of ARNs of the additional metric alarms |
| additional_metric_alarm_names | Map of names of the additional metric alarms |
| composite_alarm_ids | Map of IDs of the composite alarms |
| composite_alarm_arns | Map of ARNs of the composite alarms |
| composite_alarm_names | Map of names of the composite alarms |
| dashboard_arn | The ARN of the dashboard |
| dashboard_name | The name of the dashboard |
| log_group_arn | The ARN of the log group |
| log_group_name | The name of the log group |
| metric_filter_ids | Map of IDs of the metric filters |
| metric_filter_names | Map of names of the metric filters |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later

## Notes

- This module follows the principle of separation of concerns by focusing only on CloudWatch resources
- For production environments, it's recommended to set up appropriate alarm actions (e.g., SNS topics)
- When using composite alarms, make sure to reference the correct alarm ARNs
- The module supports both simple and complex metric alarm configurations
- Dashboard JSON should follow the CloudWatch dashboard JSON syntax
- Log group retention periods should be set according to your data retention policies
