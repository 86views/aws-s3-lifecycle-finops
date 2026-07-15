output "bucket_name" {
  value = module.s3_lifecycle.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.s3_lifecycle.cloudfront_distribution_id
}