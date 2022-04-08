data "aws_caller_identity" "current" {}

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
        "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/todolist",
        "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/todolist/index/*"
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

resource "aws_lambda_function" "todolist_add_item_function" {
  filename = local.jar_file
  function_name = "todolist_add_item_function"
  role = aws_iam_role.todolist_lambda_role.arn
  handler = "kz.sabyrzhan.awslambdatodo.AddItemHandler"
  runtime = "java11"
  memory_size = 256
  source_code_hash = filebase64sha256(local.jar_file)
  timeout = 120
}

resource "aws_lambda_function" "todolist_get_items_function" {
  filename = local.jar_file
  function_name = "todolist_get_items_function"
  role = aws_iam_role.todolist_lambda_role.arn
  handler = "kz.sabyrzhan.awslambdatodo.GetItemsHandler"
  runtime = "java11"
  memory_size = 256
  source_code_hash = filebase64sha256(local.jar_file)
  timeout = 120
}