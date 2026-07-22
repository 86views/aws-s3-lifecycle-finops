variable "environment" {
  description = "Environment"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "cloudfront_enabled" {
  description = "Enable CloudFront"
  type        = bool
}

variable "enable_kms_encryption" {
  description = "Enable server-side encryption with AWS KMS"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN used for S3 bucket encryption when KMS is enabled"
  type        = string
  default     = null
}