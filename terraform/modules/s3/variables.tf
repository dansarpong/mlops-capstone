variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error."
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Enable versioning."
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable server-side encryption."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use."
  type        = string
  default     = "AES256"
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "A list of lifecycle rules for the S3 bucket. Each rule is an object."
  type = list(object({
    id                                     = string
    enabled                                = bool
    filter_prefix                          = optional(string, "")
    abort_incomplete_multipart_upload_days = optional(number)
    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    transition = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })))
    noncurrent_version_expiration = optional(object({
      days                      = number
      newer_noncurrent_versions = optional(number)
    }))
    noncurrent_version_transition = optional(list(object({
      days          = number
      storage_class = string
    })))
  }))
  default = []
}

variable "enable_public_access" {
  description = "Enable public access to the bucket. When true, allows public access for specified paths."
  type        = bool
  default     = false
}

variable "public_access_paths" {
  description = "List of paths/prefixes that should be publicly accessible. Each path will allow public read access."
  type        = list(string)
  default     = []
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  type        = bool
  default     = true
}
