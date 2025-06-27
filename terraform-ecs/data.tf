# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-west-2a"] # change as needed
  }
}

# Get a second subnet in different AZ for ALB (required for HA)
data "aws_subnet" "secondary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-west-2b"] # different AZ
  }
}

# Alternative: Get all subnets (current approach)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ecr_repository" "my_repo" {
  name = "fusion"
}

data "aws_efs_file_system" "psu" {
  tags = {
    Name = "PSU persistent storage"
  }
}