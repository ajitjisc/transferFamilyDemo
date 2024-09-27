provider "aws" {
  region = "eu-west-2"
}

terraform {
    backend "s3" {
      bucket = "la-sftp-datahub-tfstate-transfer-family-demo"
      key = "la-sftp/terraform.tfstate"
      region = "eu-west-2"
      dynamodb_table  = "terraform_locks"
    }
}

variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type        = string
  default     = "transfer-family-dev"
}