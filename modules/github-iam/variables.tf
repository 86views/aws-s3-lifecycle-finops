variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "bucket_name" {
  description = "S3 Bucket name"
  type        = string
}

variable "cost_center" {
  description = "Cost center code"
  type        = string
  default     = ""
}

variable "github_owner_id" {
  description = "Immutable GitHub owner/org ID (from OIDC sub claim)"
  type        = string
}

variable "github_repo_id" {
  description = "Immutable GitHub repository ID (from OIDC sub claim)"
  type        = string
}