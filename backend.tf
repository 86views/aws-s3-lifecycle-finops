terraform {
  backend "s3" {
    bucket = "tf-state-7afc2a05" # Keep your real bucket name
    key    = "aws-s3-lifecycle-finops/terraform.tfstate"
    region = "us-east-1"

    # ✅ Replace dynamodb_table with native S3 locking
    use_lockfile = true

    encrypt = true
  }
}