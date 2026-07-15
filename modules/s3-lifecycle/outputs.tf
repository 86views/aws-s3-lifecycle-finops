output "bucket_name" {
  value = aws_s3_bucket.main.id
}

output "cloudfront_distribution_id" {
  value = try(aws_cloudfront_distribution.main[0].id, null)
}