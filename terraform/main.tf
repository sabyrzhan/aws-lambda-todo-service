terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "kz.sabyrzhan.terraform.backend"
    key    = "aws_lambda_todolist/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  source_root = "${path.module}/.."
  jar_file = "${local.source_root}/target/aws-lambda-todo-service.jar"
}

resource "aws_lambda_function" "todolist_function" {
  filename = local.jar_file
  function_name = "todolist_function"
  role = aws_iam_role.todolist_lambda_role.arn
  handler = "kz.sabyrzhan.awslambdatodo.AddItemHandler"
  runtime = "java11"
  memory_size = 256
  source_code_hash = filebase64sha256(local.jar_file) #"data.archive_file.mainzip.output_base64sha256"
  timeout = 120
}


resource "aws_dynamodb_table" "todolist_table" {
  name           = "todolist"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "user_id"
  range_key      = "create_ts"

  attribute {
    name = "user_id"
    type = "N"
  }

  attribute {
    name = "create_ts"
    type = "N"
  }
}

resource "aws_iam_role_policy" "access_table_policy" {
  name = "access_table_policy"
  role = aws_iam_role.todolist_lambda_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchWriteItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": [
        "${aws_dynamodb_table.todolist_table.arn}",
        "${aws_dynamodb_table.todolist_table.arn}/index/*"
      ]
   }
  ]
}
EOF
}

resource "aws_iam_role" "todolist_lambda_role" {
  name = "todolist_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}