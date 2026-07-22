output "plan_role_arn" {
  description = "ARN of the read-only Terraform plan role"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "ARN of the Terraform apply role"
  value       = aws_iam_role.apply.arn
}