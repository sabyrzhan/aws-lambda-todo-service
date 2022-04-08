terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "kz.sabyrzhan.terraform.backend"
    key    = "aws_lambda_todolist/terraform_ddb.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}