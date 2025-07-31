# Data source for existing Elastic IP (when provided)
data "aws_eip" "existing" {
  count = var.existing_elastic_ip_id != null ? 1 : 0
  id    = var.existing_elastic_ip_id
}
