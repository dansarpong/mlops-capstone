variable "name" {
  description = "Name of the IAM role"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to IAM role name"
  type        = string
  default     = null
}

variable "path" {
  description = "Path of IAM role"
  type        = string
  default     = "/"
}

variable "description" {
  description = "Description of IAM role"
  type        = string
  default     = "IAM role managed by Terraform"
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) for the role"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching any policies the role has before destroying it"
  type        = bool
  default     = true
}

variable "permissions_boundary_arn" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

variable "trusted_role_services" {
  description = "AWS services that can assume the role"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "ARNs of AWS entities who can assume the role"
  type        = list(string)
  default     = []
}

variable "trusted_role_actions" {
  description = "Actions of STS that are allowed for the trusted entities"
  type        = list(string)
  default     = ["sts:AssumeRole"]
}

variable "mfa_required" {
  description = "Whether MFA should be required for assuming the role"
  type        = bool
  default     = false
}

variable "policies" {
  description = "Map of policy names to policy documents"
  type        = map(string)
  default     = {}
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile"
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Name of the instance profile. If not provided, the role name will be used with '-profile' suffix"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "federated_principal" {
  description = "Federated principal for web identity federation (e.g., cognito-identity.amazonaws.com)"
  type        = string
  default     = null
}

variable "federated_conditions" {
  description = "Conditions for federated principal trust policy"
  type        = any
  default     = null
}
