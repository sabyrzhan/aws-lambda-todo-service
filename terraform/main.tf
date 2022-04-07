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

resource "aws_lambda_function" "todolist_add_item_function" {
  filename = local.jar_file
  function_name = "todolist_add_item_function"
  role = aws_iam_role.todolist_lambda_role.arn
  handler = "kz.sabyrzhan.awslambdatodo.AddItemHandler"
  runtime = "java11"
  memory_size = 256
  source_code_hash = filebase64sha256(local.jar_file) #"data.archive_file.mainzip.output_base64sha256"
  timeout = 120
}

resource "aws_lambda_function" "todolist_get_items_function" {
  filename = local.jar_file
  function_name = "todolist_get_items_function"
  role = aws_iam_role.todolist_lambda_role.arn
  handler = "kz.sabyrzhan.awslambdatodo.GetItemsHandler"
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

resource "aws_iam_role" "todolist_api_gw_role" {
  name = "todolist_api_gw_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "todolist_api_gw_role_policy" {
  name = "todolist_api_gw_role_policy"
  role   = aws_iam_role.todolist_api_gw_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
   }
  ]
}
EOF
}

resource "aws_apigatewayv2_api" "todolist_api" {
  name          = "todolist_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "todolist_lambda_api_gw_stage" {
  api_id = aws_apigatewayv2_api.todolist_api.id
  name    = "todolist_lambda_api_gw_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.todolist_api_log_group.arn
    format          = jsonencode({
        requestId               = "$context.requestId"
        sourceIp                = "$context.identity.sourceIp"
        requestTime             = "$context.requestTime"
        protocol                = "$context.protocol"
        httpMethod              = "$context.httpMethod"
        resourcePath            = "$context.resourcePath"
        routeKey                = "$context.routeKey"
        status                  = "$context.status"
        responseLength          = "$context.responseLength"
        integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "todolist_add_item_integration" {
  api_id           = aws_apigatewayv2_api.todolist_api.id

  integration_type = "AWS_PROXY"
  connection_type = "INTERNET"
  integration_method = "POST"
  integration_uri = aws_lambda_function.todolist_add_item_function.invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "todolist_get_items_integration" {
  api_id           = aws_apigatewayv2_api.todolist_api.id

  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = aws_lambda_function.todolist_get_items_function.invoke_arn
}

resource "aws_cloudwatch_log_group" "todolist_api_log_group" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.todolist_api.name}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_route" "todolist_add_item_route" {
  api_id = aws_apigatewayv2_api.todolist_api.id

  route_key = "POST /todolist"
  target    = "integrations/${aws_apigatewayv2_integration.todolist_add_item_integration.id}"
}

resource "aws_apigatewayv2_route" "todolist_get_items_route" {
  api_id = aws_apigatewayv2_api.todolist_api.id

  route_key = "GET /todolist"
  target    = "integrations/${aws_apigatewayv2_integration.todolist_get_items_integration.id}"
}

resource "aws_lambda_permission" "api_gw_call_get_items_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.todolist_get_items_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.todolist_api.execution_arn}/*/*"
}

output "todolist_api_gw_base_url" {
  description = "Base URL for API Gateway stage."
  value = aws_apigatewayv2_stage.todolist_lambda_api_gw_stage.invoke_url
}