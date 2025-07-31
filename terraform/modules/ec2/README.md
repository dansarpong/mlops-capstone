# EC2 Module with Instance Scheduler

This Terraform module creates an EC2 instance with optional elastic IP association and automated start/stop scheduling capabilities using AWS EventBridge Scheduler.

## Features

- **EC2 Instance Creation**: Creates a configurable EC2 instance with security groups, key pairs, and user data
- **Automated Key Pair Management**: Option to create and manage SSH key pairs
- **Instance Scheduler**: Automated start/stop scheduling using AWS EventBridge Scheduler with customizable cron expressions and timezones
- **Elastic IP**: Support for adding both new and existing Elastic IPs
- **IAM Integration**: Automated IAM role and policy creation for scheduler permissions

## Usage

### Basic EC2 Instance

```hcl
module "ec2_instance" {
  source = "./modules/ec2"

  name                   = "my-instance"
  ami_id                = "ami-0abcdef1234567890"
  instance_type         = "t3.micro"
  subnet_id             = "subnet-12345678"
  security_group_ids    = ["sg-12345678"]
  
  create_key_pair       = true
  
  tags = {
    Environment = "development"
    Project     = "event-planner"
  }
}
```

### EC2 Instance with Scheduler and Elastic IP

```hcl
module "scheduled_server" {
  source = "./modules/ec2"

  name                = "scheduled-server"
  ami_id              = "ami-0abcdef1234567890"
  instance_type       = "t3.micro"
  subnet_id           = "subnet-12345678"
  security_group_ids  = ["sg-12345678"]
  
  # Elastic IP Configuration
  allocate_elastic_ip            = true
  elastic_ip_domain              = "vpc"
  
  # Instance Scheduler Configuration
  enable_instance_scheduler      = true
  start_schedule_expression      = "cron(0 8 ? * MON-FRI *)"  # 8 AM weekdays
  stop_schedule_expression       = "cron(0 18 ? * MON-FRI *)" # 6 PM weekdays
  schedule_timezone              = "America/New_York"
  scheduler_role_arn             = "arn:aws:iam::123456789012:role/SchedulerRole"
  
  tags = {
    Environment = "development"
    Project     = "event-planner"
    Scheduled   = "true"
  }
}
```

### Advanced Configuration

```hcl
module "ec2_instance_advanced" {
  source = "./modules/ec2"

  name                   = "advanced-instance"
  ami_id                = "ami-0abcdef1234567890"
  instance_type         = "t3.medium"
  subnet_id             = "subnet-12345678"
  security_group_ids    = ["sg-12345678", "sg-87654321"]
  root_volume_size      = 20
  
  # Use existing key pair
  key_name              = "existing-key"
  create_key_pair       = false
  
  # Custom user data
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker
  EOF
  )
  
  # Instance scheduler with custom timezone
  enable_instance_scheduler = true
  start_schedule_expression = "cron(0 7 * * MON-FRI *)"   # Start at 7 AM
  stop_schedule_expression  = "cron(0 19 * * MON-FRI *)"  # Stop at 7 PM
  schedule_timezone         = "Europe/London"
  
  iam_instance_profile = "my-instance-profile"
  
  tags = {
    Environment = "staging"
    Project     = "event-planner"
    Owner       = "devops-team"
  }
}
```

## Schedule Expression Examples

The module uses AWS EventBridge Scheduler cron expressions. Here are some common patterns:

| Description | Expression |
|-------------|------------|
| Every weekday at 8 AM UTC | `cron(0 8 ? * MON-FRI *)` |
| Every day at 9:30 PM UTC | `cron(30 21 ? * * *)` |
| Monday to Friday at 6 AM UTC | `cron(0 6 ? * MON-FRI *)` |
| Every hour during business hours | `cron(0 9-17 ? * MON-FRI *)` |
| First day of every month at midnight | `cron(0 0 1 * ? *)` |

## Supported Timezones

Common timezone examples:

- `UTC` (default)
- `America/New_York`
- `America/Los_Angeles`
- `Europe/London`
- `Europe/Paris`
- `Asia/Tokyo`
- `Australia/Sydney`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the EC2 instance | `string` | n/a | yes |
| ami_id | AMI ID for the instance | `string` | n/a | yes |
| instance_type | EC2 instance type | `string` | n/a | yes |
| subnet_id | Subnet ID to launch the instance in | `string` | n/a | yes |
| security_group_ids | List of security group IDs to associate | `list(string)` | `[]` | no |
| root_volume_size | Size of the root EBS volume in GiB | `number` | `8` | no |
| key_name | Key pair name for SSH access | `string` | `null` | no |
| create_key_pair | Whether to create a new key pair | `bool` | `false` | no |
| user_data | User data script to run on launch | `string` | `null` | no |
| iam_instance_profile | IAM instance profile to attach | `string` | `null` | no |
| enable_instance_scheduler | Whether to enable instance scheduler | `bool` | `false` | no |
| start_schedule_expression | Schedule expression for starting the instance | `string` | `"cron(0 8 ? * MON-FRI *)"` | no |
| stop_schedule_expression | Schedule expression for stopping the instance | `string` | `"cron(0 18 ? * MON-FRI *)"` | no |
| schedule_timezone | Timezone for the schedule expressions | `string` | `"UTC"` | no |
| scheduler_group_name | Name of the scheduler group | `string` | `"ec2-instance-scheduler"` | no |
| allocate_elastic_ip | Enable/disable Elastic IP allocation | `bool` | `false` | no |
| elastic_ip_domain | Domain for the Elastic IP (e.g., `vpc`) | `string` | `"vpc"` | no |
| existing_elastic_ip_id | ID of an existing Elastic IP to associate | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the EC2 instance |
| public_ip | The public IP address of the instance |
| private_ip | The private IP address of the instance |
| arn | The ARN of the EC2 instance |
| key_pair_name | The name of the key pair used |
| private_key_pem | The private key in PEM format (sensitive) |
| scheduler_enabled | Whether instance scheduler is enabled |
| scheduler_group_name | Name of the scheduler group |
| start_schedule_name | Name of the start schedule |
| stop_schedule_name | Name of the stop schedule |
| start_schedule_expression | Start schedule expression |
| stop_schedule_expression | Stop schedule expression |
| scheduler_role_arn | ARN of the scheduler IAM role |
| elastic_ip_allocated | Whether an Elastic IP is allocated |
| elastic_ip_id | The allocation ID of the Elastic IP |
| elastic_ip_address | The actual Elastic IP address |
| elastic_ip_public_dns | The public DNS name associated with the Elastic IP |


## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.2 |
| aws | >= 5.83 |
| tls | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.83 |
| tls | >= 3.0 |

## Notes

- The instance scheduler uses AWS EventBridge Scheduler, which is available in most AWS regions
- Schedules are created in the `ENABLED` state by default
- Failed schedule executions are automatically retried up to 3 times
- Instance state changes may take a few minutes to complete after the scheduled time
- Elastic IPs are allocated in the specified domain (default is `vpc`)
- Ensure the IAM role has permissions to manage EC2 instances and EventBridge Scheduler
