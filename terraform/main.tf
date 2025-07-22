# S3
module "devops_s3" {
  source = "./modules/s3"

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