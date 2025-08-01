provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = var.tags
  }
}

terraform {
  backend "s3" {
    bucket       = "dansarpong-tf"
    key          = "mlops-capstone/terraform/environments/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
