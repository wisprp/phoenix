variable "phx_prefix" {
  default = "scpoc"
}

# application lambdas
module "transform-parsoid" {
  source              = "./lambdas"
  phx_prefix          = var.phx_prefix
  lambda_name         = "transform-parsoid"
}

# S3 buckets
module "canonical-content-store" {
  source              = "./buckets"
  phx_prefix          = var.phx_prefix
  bucket_name         = "canonical-content-store"
}

# SNS
module "sns-raw-content-incoming" {
  source              = "./sns"
  phx_prefix          = var.phx_prefix
  sns_name            = "sns-raw-content-incoming"
}
