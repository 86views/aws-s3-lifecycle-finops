variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment (Dev/Prod)"
  type        = string
  default     = "Dev"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "cost_center" {
  description = "Cost center for tagging"
  type        = string
}

variable "cloudfront_enabled" {
  description = "Enable CloudFront distribution"
  type        = bool
  default     = true
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


variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}