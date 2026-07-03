output "bedrock_status" {
  description = "Confirmation that Bedrock has been configured"
  value       = "Amazon Bedrock access has been configured in ${var.aws_region} with profile ${var.aws_profile}"
}

output "bedrock_logging_bucket" {
  description = "Name of the S3 bucket for Bedrock logs"
  value       = aws_s3_bucket.bedrock_logs.id
}

output "bedrock_execution_role_arn" {
  description = "ARN of the IAM role for Bedrock access"
  value       = aws_iam_role.bedrock_execution_role.arn
}

output "next_steps" {
  description = "Next steps to use Amazon Bedrock"
  value       = <<EOT

  Next steps:
  1. Run 'terraform init' to initialize the Terraform configuration
  2. Run 'terraform plan' to see the execution plan
  3. Run 'terraform apply' to apply the configuration
  4. After applying, you can use the AWS CLI to test Bedrock access:
     
     # List available foundation models:
     aws bedrock list-foundation-models \
       --profile ${var.aws_profile} \
       --region ${var.aws_region}
     
     # Example to invoke a model (replace MODEL_ID with actual model ID):
     # aws bedrock invoke-model \
     #   --model-id MODEL_ID \
     #   --content-type "application/json" \
     #   --body '{"prompt":"Hello, how are you?"}' \
     #   output.json \
     #   --profile ${var.aws_profile} \
     #   --region ${var.aws_region}
  EOT
}
