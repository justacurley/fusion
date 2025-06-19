# Create an S3 bucket for storing Terraform state
#trivy:ignore:AVD-AWS-0094
#trivy:ignore:AVD-AWS-0093
#trivy:ignore:AVD-AWS-0091
#trivy:ignore:AVD-AWS-0089
#trivy:ignore:AVD-AWS-0087
#trivy:ignore:AVD-AWS-0086
resource "aws_s3_bucket" "terraform_state" {
  bucket = "fusion-statefiles" # Change this to a unique bucket name

  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "private_bucket_access" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Enable server-side encryption
#trivy:ignore:AVD-AWS-0132 
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create an S3 bucket policy to enforce encryption in transit
resource "aws_s3_bucket_policy" "terraform_state_policy" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceEncryptionInTransit"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowSpecificIAMUser"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::471230323408:user/terraform"
        }
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
    ]
  })
}
