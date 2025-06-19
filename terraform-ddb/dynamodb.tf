# DynamoDB table for health tracking entries
# Schema derived from entries.json structure

resource "aws_dynamodb_table" "health_entries" {
  name         = "${var.table_name_prefix}-health-entries"
  billing_mode = var.billing_mode
  hash_key     = "date"      # Partition key: date in MMDD format
  range_key    = "timestamp" # Sort key: time entry (HHMM format)

  # Conditional capacity settings for PROVISIONED mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Partition key: Date (string, e.g., "0523")
  attribute {
    name = "date"
    type = "S"
  }

  # Sort key: Timestamp (string, e.g., "1300")
  attribute {
    name = "timestamp"
    type = "S"
  }

  # Global Secondary Index for querying by medication
  attribute {
    name = "medication_taken"
    type = "S"
  }

  # Global Secondary Index for querying by pain level
  attribute {
    name = "max_pain_level"
    type = "N"
  }

  # GSI for medication tracking
  global_secondary_index {
    name            = "medication-index"
    hash_key        = "medication_taken"
    range_key       = "date"
    projection_type = "ALL"
  }

  # GSI for pain level tracking
  global_secondary_index {
    name            = "pain-level-index"
    hash_key        = "max_pain_level"
    range_key       = "date"
    projection_type = "ALL"
  }

  # Enable point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Deletion protection for production
  deletion_protection_enabled = var.enable_deletion_protection

  tags = {
    Name        = "${var.table_name_prefix}-health-entries"
    Environment = var.environment
    Project     = var.table_name_prefix
    DataType    = "health-tracking"
  }
}

# DynamoDB table for daily summaries
resource "aws_dynamodb_table" "daily_summaries" {
  name         = "${var.table_name_prefix}-daily-summaries"
  billing_mode = var.billing_mode
  hash_key     = "date"

  # Conditional capacity settings for PROVISIONED mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Partition key: Date (string, e.g., "0523")
  attribute {
    name = "date"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Deletion protection
  deletion_protection_enabled = var.enable_deletion_protection

  tags = {
    Name        = "${var.table_name_prefix}-daily-summaries"
    Environment = var.environment
    Project     = var.table_name_prefix
    DataType    = "daily-health-summary"
  }
}

# IAM role for DynamoDB access
resource "aws_iam_role" "dynamodb_access_role" {
  name = "${var.table_name_prefix}-dynamodb-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "${var.table_name_prefix}-dynamodb-access-role"
    Project     = var.table_name_prefix
    Environment = var.environment
  }
}

# IAM policy for DynamoDB operations
resource "aws_iam_role_policy" "dynamodb_access_policy" {
  name = "${var.table_name_prefix}-dynamodb-access-policy"
  role = aws_iam_role.dynamodb_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.health_entries.arn,
          "${aws_dynamodb_table.health_entries.arn}/*",
          aws_dynamodb_table.daily_summaries.arn,
          "${aws_dynamodb_table.daily_summaries.arn}/*"
        ]
      }
    ]
  })
}
