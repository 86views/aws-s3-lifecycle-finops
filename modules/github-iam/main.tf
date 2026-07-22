data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ------------------------------------------------------------------------------
# PLAN ROLE — read-only, assumable from any workflow run in this repo
# (pull_request runs, and pushes to main/master)
# ------------------------------------------------------------------------------

resource "aws_iam_role" "plan" {
  name = "github-actions-${var.project}-${var.environment}-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
    Purpose     = "github-actions-plan"
  }
}

resource "aws_iam_role_policy" "plan" {
  name = "github-actions-plan-readonly"
  role = aws_iam_role.plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::tf-state-7afc2a05",
          "arn:aws:s3:::tf-state-7afc2a05/*"
        ]
      },
      {
        Sid    = "S3ReadOnlyForRefresh"
        Effect = "Allow"
        Action = [
          "s3:GetBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:GetBucketTagging",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketOwnershipControls",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Sid    = "CloudFrontReadOnly"
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListDistributions"
        ]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# APPLY ROLE — mutating access, scoped to the "production" GitHub Environment ONLY
# This means only workflow jobs that declare `environment: production`
# (and pass any required reviewer approval) can assume this role.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "apply" {
  name = "github-actions-${var.project}-${var.environment}-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:environment:production"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
    Purpose     = "github-actions-apply"
  }
}

resource "aws_iam_role_policy" "apply" {
  name = "github-actions-s3-cloudfront-apply"
  role = aws_iam_role.apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::tf-state-7afc2a05",
          "arn:aws:s3:::tf-state-7afc2a05/*"
        ]
      },
      {
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution"]
        Resource = "*"
      }
    ]
  })
}