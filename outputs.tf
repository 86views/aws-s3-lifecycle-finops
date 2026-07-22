output "bucket_name" {
  value = module.s3_lifecycle.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.s3_lifecycle.cloudfront_distribution_id
}


output "github_plan_role_arn" {
  description = "ARN of the read-only Terraform plan role"
  value       = module.github_iam.plan_role_arn
}

output "github_apply_role_arn" {
  description = "ARN of the Terraform apply role"
  value       = module.github_iam.apply_role_arn
}

output "project" {
  description = "Project name"
  value       = var.project
}

output "cost_center" {
  description = "Cost center"
  value       = var.cost_center
}