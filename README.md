# Automated S3 Lifecycle & FinOps Infrastructure

## Architecture Overview

This Terraform project provisions an S3 bucket with automated lifecycle policies for cost optimization, versioning control, incomplete upload cleanup, mandatory tagging, and optional CloudFront distribution with Origin Access Control (OAC) to prevent direct public access and reduce egress costs.

### Storage Lifecycle Matrix
- **0-30 days**: S3 Standard
- **31-90 days**: S3 Standard-IA
- **91-365 days**: Glacier Flexible Retrieval
- **365+ days**: Glacier Deep Archive

Additional rules:
- Abort incomplete multipart uploads after 7 days.
- Non-current versions to IA after 14 days, expire after 90 days.

## Prerequisites
- AWS account (Free Tier compatible)
- Terraform >= 1.9
- GitHub repository

**GitHub Secrets** (OIDC-based):
- `AWS_ROLE_ARN` → ARN of the IAM Role with `AssumeRole` trust for GitHub
- `BUCKET_NAME`
- `PROJECT`
- `COST_CENTER`

**Note**: For Free Tier, use a unique bucket name and minimal data.

## Deployment Steps (Local)
1. Clone the repo.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill values.
3. `terraform init`
4. `terraform plan`
5. `terraform apply`

### CI/CD (GitHub Actions with OIDC)
- On PR: Runs `terraform plan`
- On merge to `master`: Runs `terraform apply`

See AWS setup instructions below.

## FinOps Cost Savings Forecast
- **Lifecycle transitions**: Can reduce storage costs by 40-70% for cold data.
- **Versioning cleanup**: Prevents bloat (savings depend on churn rate).
- **CloudFront OAC**: Eliminates direct S3 egress fees.
- **Tagging**: Enables precise cost allocation and alerts.

Monitor via AWS Cost Explorer. Expected savings: Significant for data >90 days old.

## AWS OIDC Setup (Recommended - No Long-term Credentials)
1. Create an IAM Role in AWS with necessary permissions (S3 full access, CloudFront, etc.).
2. Add GitHub as trusted identity provider:
   - Audience: `sts.amazonaws.com`
   - Subject: `repo:YOUR_GITHUB_ORG/REPO_NAME:ref:refs/heads/master` (or broader for PRs)
3. Set the Role ARN as GitHub secret `AWS_ROLE_ARN`.

See official guide: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## Customization
Edit module variables and lifecycle rules as needed. For production, add KMS encryption, logging, etc.

## Free Tier Considerations
- S3 Standard has generous free tier limits.
- CloudFront has free tier data transfer.
- Avoid high retrievals from Glacier.

## You can download the repo for learning purposes and understanding aws, terraform and devloped by Olueye Oluse