terraform {
  required_version = "1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
  }
}
provider "aws" {
  region = "us-west-2" # Change this to your desired region
  default_tags {
    tags = {
      "Owner" = "Alex Curley"
    }
  }
}