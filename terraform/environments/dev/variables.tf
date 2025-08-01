variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "mlops"
}

variable "environment" {
  description = "The name of the environment"
  type        = string
  default     = "mlops-dev"
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default = {
    "Project"     = "MLOps Capstone",
    "Environment" = "mlops-dev",
    "ManagedBy"   = "Terraform"
  }
}

# VPC
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets_cidr" {
  description = "The CIDR blocks for the public subnets"
  type        = string
  default     = "10.1.0.0/20"
}

variable "private_subnets_cidr" {
  description = "The CIDR blocks for the private subnets"
  type        = string
  default     = "10.1.16.0/20"
}

variable "az_count" {
  description = "The number of availability zones to use"
  type        = number
  default     = 2
}

# Security Groups
variable "ports" {
  description = "A map of ports to open in the security group"
  type        = map(number)
  default = {
    ssh      = 22
    web      = 80
    https    = 443
    postgres = 5432
  }
}


# EC2 Instance
variable "instance_type" {
  description = "Instance type for the ASG EC2 instances"
  type        = string
  default     = "t3.medium"
}

variable "amzn_2023_ami" {
  description = "Amazon Linux 2023 AMI ID"
  type        = string
  default     = "ami-08a6efd148b1f7504"
}

variable "key_pair_name" {
  description = "Name of the key pair for SSH access"
  type        = string
  default     = "mlops-dev-key"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB"
  type        = number
  default     = 20
}

# RDS
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "17.4"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database (GB)"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
