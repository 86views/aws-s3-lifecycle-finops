output "bucket_name" {
  value = module.s3_lifecycle.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.s3_lifecycle.cloudfront_distribution_id
}


output "github_role_arn" {
  value = module.github_iam.role_arn
}

output "project" {
  description = "Project name"
  value       = var.project
}

output "cost_center" {
  description = "Cost center"
  value       = var.cost_center
}