# S3 Module

This Terraform module creates an AWS S3 bucket with optional public access configuration for specific paths.

## Features

- S3 bucket creation with customizable settings
- Versioning control
- Server-side encryption
- Lifecycle rules
- **Public access control for specific paths/files**
- Bucket policies for granular access control

## Usage

### Basic Private Bucket (Default)

```hcl
module "s3_bucket" {
  source = "./modules/s3"

  bucket_name = "my-private-bucket"
  versioning  = true
}
```

### Bucket with Public Access for Specific Paths

```hcl
module "s3_public_assets" {
  source = "./modules/s3"

  bucket_name = "my-app-assets"
  versioning  = true

  # Enable public access
  enable_public_access = true
  
  # Configure public access blocks (must be false to allow public access)
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Define publicly accessible paths
  public_access_paths = [
    "public/*",        # All files under public/ prefix
    "assets/images/*", # All images under assets/images/
    "favicon.ico",     # Specific file
  ]
}
```

## Public Access Configuration

To enable public access for certain paths in your S3 bucket:

1. **Set `enable_public_access = true`** - This enables the public access feature
2. **Configure public access blocks** - Set these to `false` to allow public access:
   - `block_public_acls = false`
   - `block_public_policy = false`
   - `ignore_public_acls = false`
   - `restrict_public_buckets = false`
3. **Define `public_access_paths`** - List the paths/prefixes that should be publicly accessible

### Path Examples

- `"public/*"` - All files under the `public/` prefix
- `"assets/images/*"` - All files under `assets/images/` prefix
- `"static/css/*.css"` - All CSS files under `static/css/`
- `"favicon.ico"` - Specific file
- `"docs/api/*"` - All files under `docs/api/` prefix

### Security Considerations

⚠️ **Important Security Notes:**

1. **Only enable public access when absolutely necessary**
2. **Be specific with your paths** - Use precise prefixes rather than broad wildcards
3. **Regularly audit your public paths** - Review what's publicly accessible
4. **Consider using CloudFront** - For better performance and security
5. **Monitor access logs** - Keep track of who's accessing your public content

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `bucket_name` | The name of the S3 bucket | `string` | - | yes |
| `enable_public_access` | Enable public access to the bucket | `bool` | `false` | no |
| `public_access_paths` | List of paths that should be publicly accessible | `list(string)` | `[]` | no |
| `block_public_acls` | Whether to block public ACLs | `bool` | `true` | no |
| `block_public_policy` | Whether to block public bucket policies | `bool` | `true` | no |
| `ignore_public_acls` | Whether to ignore public ACLs | `bool` | `true` | no |
| `restrict_public_buckets` | Whether to restrict public bucket policies | `bool` | `true` | no |
| `versioning` | Enable versioning | `bool` | `false` | no |
| `enable_encryption` | Enable server-side encryption | `bool` | `true` | no |
| `sse_algorithm` | Server-side encryption algorithm | `string` | `"AES256"` | no |
| `force_destroy` | Allow bucket destruction with objects | `bool` | `false` | no |
| `lifecycle_rules` | List of lifecycle rules | `list(object)` | `[]` | no |
| `tags` | Map of tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | The name of the bucket |
| `bucket_arn` | The ARN of the bucket |
| `bucket_domain_name` | The bucket domain name |
| `bucket_website_endpoint` | The website endpoint |
| `public_access_enabled` | Whether public access is enabled |
| `public_access_paths` | List of publicly accessible paths |

## Examples

See `examples.tf` for detailed usage examples.

## Accessing Public Files

Once configured, your public files will be accessible via:

```
https://s3.amazonaws.com/YOUR-BUCKET-NAME/PATH-TO-FILE
```

For example, if your bucket is `my-app-assets` and you have a file at `public/logo.png`:

```
https://s3.amazonaws.com/my-app-assets/public/logo.png
```
