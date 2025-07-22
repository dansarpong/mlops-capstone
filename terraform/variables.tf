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
  default     = {
    "Project"     = "MLOps Capstone",
    "Environment" = "mlops-dev",
    "ManagedBy"   = "Terraform"
  }  
}
