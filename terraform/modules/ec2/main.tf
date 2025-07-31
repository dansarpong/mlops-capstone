resource "aws_key_pair" "this" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_name != null ? var.key_name : var.name
  public_key = tls_private_key.this[0].public_key_openssh
}

resource "tls_private_key" "this" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
  user_data              = var.user_data
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# Instance Scheduler
# Scheduler Group
resource "aws_scheduler_schedule_group" "this" {
  count = var.enable_instance_scheduler ? 1 : 0
  name  = var.scheduler_group_name

  tags = merge(
    var.tags,
    {
      Name = var.scheduler_group_name
    }
  )
}

# Schedule to Start Instance
resource "aws_scheduler_schedule" "start_instance" {
  count       = var.enable_instance_scheduler ? 1 : 0
  name        = "${var.name}-start-schedule"
  group_name  = aws_scheduler_schedule_group.this[0].name
  description = "Schedule to start EC2 instance ${var.name}"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.start_schedule_expression
  schedule_expression_timezone = var.schedule_timezone
  state                        = "ENABLED"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = var.scheduler_role_arn

    input = jsonencode({
      InstanceIds = [aws_instance.this.id]
    })

    retry_policy {
      maximum_retry_attempts = 3
    }
  }
}

# Schedule to Stop Instance
resource "aws_scheduler_schedule" "stop_instance" {
  count       = var.enable_instance_scheduler ? 1 : 0
  name        = "${var.name}-stop-schedule"
  group_name  = aws_scheduler_schedule_group.this[0].name
  description = "Schedule to stop EC2 instance ${var.name}"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.stop_schedule_expression
  schedule_expression_timezone = var.schedule_timezone
  state                        = "ENABLED"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = var.scheduler_role_arn

    input = jsonencode({
      InstanceIds = [aws_instance.this.id]
    })

    retry_policy {
      maximum_retry_attempts = 3
    }
  }
}

# Elastic IP Resources
resource "aws_eip" "this" {
  count  = var.allocate_elastic_ip && var.existing_elastic_ip_id == null ? 1 : 0
  domain = var.elastic_ip_domain

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eip"
    }
  )

  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "aws_eip_association" "this" {
  count       = (var.allocate_elastic_ip || var.existing_elastic_ip_id != null) ? 1 : 0
  instance_id = aws_instance.this.id
  allocation_id = var.existing_elastic_ip_id != null ? var.existing_elastic_ip_id : aws_eip.this[0].id

  depends_on = [aws_instance.this]
}
