# GitHub IAM Role for CI/CD
module "github_iam" {
  source = "./modules/github-iam"

  github_org  = var.github_org
  github_repo = var.github_repo
  project     = var.project
  environment = var.environment
  bucket_name = var.bucket_name
  cost_center = var.cost_center
}



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

