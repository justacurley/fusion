# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

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

data "aws_ecr_repository" "my_repo" {
  name = "fusion"
}

data "aws_efs_file_system" "psu" {
  tags = {
    Name = "PSU persistent storage"
  }
}