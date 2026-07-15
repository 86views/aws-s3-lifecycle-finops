module "s3_lifecycle" {
  source = "./modules/s3-lifecycle"

  bucket_name           = var.bucket_name
  environment           = var.environment
  project               = var.project
  cost_center           = var.cost_center
  cloudfront_enabled    = var.cloudfront_enabled
  enable_kms_encryption = var.enable_kms_encryption
  kms_key_arn           = var.kms_key_arn
}

