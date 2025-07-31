# General
variable "name" {
  description = "Name to be used for resources created by this module"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to the resource names"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# CloudWatch Alarms
variable "create_metric_alarms" {
  description = "Controls if CloudWatch metric alarms should be created"
  type        = bool
  default     = true
}

variable "metric_alarms" {
  description = "Map of metric alarm configurations to create"
  type        = any
  default     = {}
}

variable "alarm_description" {
  description = "The description for the alarm"
  type        = string
  default     = "Managed by Terraform"
}

variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified statistic and threshold"
  type        = string
  default     = "GreaterThanOrEqualToThreshold"
  validation {
    condition     = contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], var.comparison_operator)
    error_message = "Valid values for comparison_operator are (GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold)."
  }
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 1
}

variable "threshold" {
  description = "The value against which the specified statistic is compared"
  type        = number
  default     = 0
}

variable "metric_name" {
  description = "The name for the alarm's associated metric"
  type        = string
  default     = null
}

variable "namespace" {
  description = "The namespace for the alarm's associated metric"
  type        = string
  default     = null
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied"
  type        = number
  default     = 60
}

variable "statistic" {
  description = "The statistic to apply to the alarm's associated metric"
  type        = string
  default     = "Average"
  validation {
    condition     = contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], var.statistic)
    error_message = "Valid values for statistic are (SampleCount, Average, Sum, Minimum, Maximum)."
  }
}

variable "actions_enabled" {
  description = "Indicates whether or not actions should be executed during any changes to the alarm's state"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state"
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "The list of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "The list of actions to execute when this alarm transitions into an OK state"
  type        = list(string)
  default     = []
}

variable "unit" {
  description = "The unit for the alarm's associated metric"
  type        = string
  default     = null
}

variable "dimensions" {
  description = "The dimensions for the alarm's associated metric"
  type        = map(string)
  default     = {}
}

variable "treat_missing_data" {
  description = "How the alarm handles missing data points"
  type        = string
  default     = "missing"
  validation {
    condition     = contains(["missing", "ignore", "breaching", "notBreaching"], var.treat_missing_data)
    error_message = "Valid values for treat_missing_data are (missing, ignore, breaching, notBreaching)."
  }
}

# CloudWatch Composite Alarms
variable "create_composite_alarms" {
  description = "Controls if CloudWatch composite alarms should be created"
  type        = bool
  default     = false
}

variable "composite_alarms" {
  description = "Map of composite alarm configurations to create"
  type        = any
  default     = {}
}

# CloudWatch Dashboards
variable "create_dashboard" {
  description = "Controls if CloudWatch dashboard should be created"
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Name of the dashboard"
  type        = string
  default     = null
}

variable "dashboard_body" {
  description = "The JSON body of the dashboard"
  type        = string
  default     = null
}

# CloudWatch Log Groups
variable "create_log_group" {
  description = "Controls if CloudWatch log group should be created"
  type        = bool
  default     = false
}

variable "log_group_name" {
  description = "Name of the log group"
  type        = string
  default     = null
}

variable "log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the log group"
  type        = number
  default     = 30
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_group_retention_in_days)
    error_message = "Valid values for log_group_retention_in_days are (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653)."
  }
}

variable "log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

# CloudWatch Metric Filters
variable "create_metric_filters" {
  description = "Controls if CloudWatch metric filters should be created"
  type        = bool
  default     = false
}

variable "metric_filters" {
  description = "Map of metric filter configurations to create"
  type        = any
  default     = {}
}
