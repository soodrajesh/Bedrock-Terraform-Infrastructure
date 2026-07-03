terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# S3 Bucket for Bedrock logs with proper configuration for AWS provider 5.x
resource "aws_s3_bucket" "bedrock_logs" {
  bucket        = "${var.project_name}-bedrock-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  # Add tags for better resource management
  tags = var.tags
}

# Configure S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "bedrock_logs_ownership" {
  bucket = aws_s3_bucket.bedrock_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Configure public access block to disable ACLs
resource "aws_s3_bucket_public_access_block" "bedrock_logs_public_access" {
  bucket = aws_s3_bucket.bedrock_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bedrock configuration
# Note: Bedrock model invocation logging is configured through the AWS Console or CLI
# as it requires AWS managed resources that can't be directly managed via Terraform

data "aws_caller_identity" "current" {}

# IAM policy for Bedrock access
resource "aws_iam_policy" "bedrock_access" {
  name        = "${var.project_name}-bedrock-access-policy"
  description = "Policy for accessing Amazon Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.bedrock_logs.arn}/*"
      }
    ]
  })
}

# Role trusted by the Bedrock service itself (e.g. for model invocation
# logging delivery to S3). This is not a role for an EC2 instance, Lambda
# function, or other client to assume when calling bedrock:InvokeModel -
# those callers need their own IAM identity granted the bedrock_access
# policy below, or need to assume a role whose trust policy names them
# (ec2.amazonaws.com, lambda.amazonaws.com, etc.) instead of bedrock.amazonaws.com.
resource "aws_iam_role" "bedrock_execution_role" {
  name = "${var.project_name}-bedrock-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_access_attachment" {
  role       = aws_iam_role.bedrock_execution_role.name
  policy_arn = aws_iam_policy.bedrock_access.arn
}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Bedrock logs"
  value       = aws_s3_bucket.bedrock_logs.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Bedrock access"
  value       = aws_iam_role.bedrock_execution_role.arn
}
