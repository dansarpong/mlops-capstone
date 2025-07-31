output "bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "public_access_enabled" {
  description = "Whether public access is enabled for this bucket."
  value       = var.enable_public_access
}

output "public_access_paths" {
  description = "List of publicly accessible paths in the bucket."
  value       = var.public_access_paths
}

output "cors_enabled" {
  description = "Whether CORS is enabled for this bucket."
  value       = var.enable_cors
}

output "cors_configuration" {
  description = "CORS configuration for the bucket."
  value       = var.enable_cors ? var.cors_rules : null
}
