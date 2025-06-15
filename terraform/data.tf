# Find the latest Windows Server AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    # Adjust the pattern for your desired Windows Server version
    values = ["Windows_Server-2022-English-Core-Base-*"]
  }
  filter {
    name   = "platform"
    values = ["windows"]
  }
}

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
    values = ["us-west-2a"]  # change as needed
  }
}
