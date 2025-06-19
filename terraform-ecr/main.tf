# ECR Repository
#trivy:ignore:AVD-AWS-0107
#trivy:ignore:AVD-AWS-0031
resource "aws_ecr_repository" "my_repo" {
  name = "fusion"
  encryption_configuration {
    encryption_type = "AES256"
  }
}
