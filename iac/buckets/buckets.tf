variable "bucket_name" {
  default = "nill"
}
variable "phx_prefix" {}

# buckets definition
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.phx_prefix}-${var.bucket_name}"
  acl    = "private"

  tags = {
    Name        = "${var.phx_prefix}-${var.bucket_name}"
  }
}
