# DynamoDB table outputs
output "health_entries_table_name" {
  value       = aws_dynamodb_table.health_entries.name
  description = "Name of the health entries DynamoDB table"
}

output "health_entries_table_arn" {
  value       = aws_dynamodb_table.health_entries.arn
  description = "ARN of the health entries DynamoDB table"
}

output "daily_summaries_table_name" {
  value       = aws_dynamodb_table.daily_summaries.name
  description = "Name of the daily summaries DynamoDB table"
}

output "daily_summaries_table_arn" {
  value       = aws_dynamodb_table.daily_summaries.arn
  description = "ARN of the daily summaries DynamoDB table"
}

# IAM role outputs
output "dynamodb_access_role_arn" {
  value       = aws_iam_role.dynamodb_access_role.arn
  description = "ARN of the IAM role for DynamoDB access"
}

output "dynamodb_access_role_name" {
  value       = aws_iam_role.dynamodb_access_role.name
  description = "Name of the IAM role for DynamoDB access"
}

# Connection information for applications
output "dynamodb_endpoint" {
  value       = "https://dynamodb.${data.aws_region.current.name}.amazonaws.com"
  description = "DynamoDB endpoint URL"
}

output "region" {
  value       = data.aws_region.current.name
  description = "AWS region where DynamoDB tables are created"
}
