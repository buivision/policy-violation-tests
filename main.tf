terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure provider with dummy settings to avoid auth errors.
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# This resource will FAIL the S3 encryption policy.
resource "aws_s3_bucket" "bad_bucket" {
  bucket = "my-bad-bucket-for-policy-testing-987123" # Must be globally unique
}

# This resource will FAIL the instance type policy.
resource "aws_instance" "bad_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # A common us-west-2 Amazon Linux 2 AMI
  instance_type = "t2.micro"

  tags = {
    Name = "Policy-Test-Instance"
  }
}