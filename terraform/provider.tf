provider "aws" {
  region = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = var.tags
  }
}
