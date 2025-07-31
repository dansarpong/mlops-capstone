variable "name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB"
  type        = number
  default     = 8
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run on launch"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "create_key_pair" {
  description = "Whether to create a new key pair for the instance. If true, a new key pair will be created and the private key will be output. If false, provide an existing key_name."
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM instance profile to attach to the EC2 instance"
  type        = string
  default     = null
}

variable "enable_instance_scheduler" {
  description = "Whether to enable instance scheduler for automatic start/stop"
  type        = bool
  default     = false
}

variable "start_schedule_expression" {
  description = "Schedule expression for starting the instance"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "stop_schedule_expression" {
  description = "Schedule expression for stopping the instance"
  type        = string
  default     = "cron(0 18 ? * MON-FRI *)"
}

variable "schedule_timezone" {
  description = "Timezone for the schedule expressions"
  type        = string
  default     = "UTC"
}

variable "scheduler_group_name" {
  description = "Name of the scheduler group"
  type        = string
  default     = "default"
}

variable "scheduler_role_arn" {
  description = "IAM Role ARN for the instance scheduler"
  type        = string
  default     = null
}

# Elastic IP Configuration
variable "allocate_elastic_ip" {
  description = "Whether to allocate and associate an Elastic IP with the instance"
  type        = bool
  default     = false
}

variable "elastic_ip_domain" {
  description = "Domain for the Elastic IP allocation (vpc or standard)"
  type        = string
  default     = "vpc"
  validation {
    condition     = contains(["vpc", "standard"], var.elastic_ip_domain)
    error_message = "Elastic IP domain must be either 'vpc' or 'standard'."
  }
}

variable "existing_elastic_ip_id" {
  description = "ID of an existing Elastic IP to associate with the instance (alternative to allocating a new one)"
  type        = string
  default     = null
}
