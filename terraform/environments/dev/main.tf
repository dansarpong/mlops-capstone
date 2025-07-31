# VPC
module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.environment}-vpc"
  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  create_subnet_types  = ["public", "private"]
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  enable_nat_gateway   = false
}

# Security Groups
module "platform_sg" {
  source = "../../modules/security-group"

  name        = "${var.environment}-platform-sg"
  description = "Security group for the platform"
  vpc_id      = module.vpc.vpc_id


  # Allow specific inbound traffic
  ingress_with_cidr_blocks = {
    web = {
      from_port   = var.ports["web"]
      to_port     = var.ports["web"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      from_port   = var.ports["https"]
      to_port     = var.ports["https"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ssh = {
      from_port   = var.ports["ssh"]
      to_port     = var.ports["ssh"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

module "db_sg" {
  source = "../../modules/security-group"

  name        = "${var.environment}-db-sg"
  description = "Security group for the RDS database"
  vpc_id      = module.vpc.vpc_id

  # Allow PostgreSQL from the platform
  ingress_with_source_security_group_id = {
    platform = {
      from_port                = var.ports["postgres"]
      to_port                  = var.ports["postgres"]
      protocol                 = "tcp"
      source_security_group_id = module.platform_sg.security_group_id
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# IAM
module "platform_instance_role" {
  source = "../../modules/iam"

  name = "${var.environment}-platform-instance-role"

  trusted_role_services = ["ec2.amazonaws.com"]
  managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]

  # RDS access
  policies = {
    RDSAccessPolicy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "rds:*"
          ],
          Resource = "*",
          Condition = {
            StringEquals = {
              "aws:ResourceTag/Environment" = var.tags["Environment"],
              "aws:ResourceTag/Project"     = var.tags["Project"]
            }
          }
        }
      ]
    })
    S3AccessPolicy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:GetObjectVersion"
          ],
          Resource = "arn:aws:s3:::${var.environment}-dansarpong-s3/*"
        }
      ]
    })
  }

  create_instance_profile = true
}

# EC2 Instance
module "platform_ec2" {
  source = "../../modules/ec2"

  name                 = "${var.environment}-ec2"
  ami_id               = var.amzn_2023_ami
  instance_type        = var.instance_type
  key_name             = var.key_pair_name
  root_volume_size     = var.root_volume_size
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.platform_sg.security_group_id]
  iam_instance_profile = module.platform_instance_role.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y

    # Install Docker
    sudo yum install -y docker
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ec2-user
  
    EOF

  # Elastic IP
  allocate_elastic_ip = true
}

# RDS
module "rds" {
  source = "../../modules/rds"

  name = "${var.environment}-rds"

  # Engine options
  engine         = var.db_engine
  engine_version = var.db_engine_version

  # Instance configuration
  instance_class = var.db_instance_class
  multi_az       = false

  # Storage
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # Authentication
  username = var.db_username
  password = var.db_password

  # Network
  port                   = var.ports["postgres"]
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = 1

  # Maintenance
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  apply_immediately  = true
}

# S3
module "devops_s3" {
  source = "../../modules/s3"

  bucket_name       = "${var.environment}-dansarpong-s3"
  versioning        = true

  lifecycle_rules = [
    {
      id            = "cleanup-old-versions"
      enabled       = true
      filter_prefix = ""
      noncurrent_version_expiration = {
        days                      = 7
        newer_noncurrent_versions = 5
      }
    },
    {
      id                                     = "cleanup-incomplete-uploads"
      enabled                                = true
      filter_prefix                          = ""
      abort_incomplete_multipart_upload_days = 1
    }
  ]
}
