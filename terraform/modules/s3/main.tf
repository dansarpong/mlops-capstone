resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = lookup(rule.value, "filter_prefix", "")
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = lookup(expiration.value, "days", null)
          date                         = lookup(expiration.value, "date", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition != null ? rule.value.transition : []
        content {
          days          = lookup(transition.value, "days", null)
          date          = lookup(transition.value, "date", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days           = noncurrent_version_expiration.value.days
          newer_noncurrent_versions = lookup(noncurrent_version_expiration.value, "newer_noncurrent_versions", null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition != null ? rule.value.noncurrent_version_transition : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.enable_public_access ? var.block_public_acls : true
  block_public_policy     = var.enable_public_access ? var.block_public_policy : true
  ignore_public_acls      = var.enable_public_access ? var.ignore_public_acls : true
  restrict_public_buckets = var.enable_public_access ? var.restrict_public_buckets : true
}

# S3 Bucket Policy for Public Access
resource "aws_s3_bucket_policy" "public_access" {
  count      = var.enable_public_access && length(var.public_access_paths) > 0 ? 1 : 0
  bucket     = aws_s3_bucket.this.id
  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for path in var.public_access_paths : {
        Sid       = "PublicReadGetObject${replace(replace(path, "/", ""), "*", "All")}"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/${path}"
      }
    ]
  })
}
