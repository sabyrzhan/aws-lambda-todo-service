data "aws_caller_identity" "current" {}

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
  integration_uri = "arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:todolist_add_item_function"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "todolist_get_items_integration" {
  api_id           = aws_apigatewayv2_api.todolist_api.id

  integration_type = "AWS_PROXY"
  connection_type = "INTERNET"
  integration_method = "POST"
  integration_uri = "arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:todolist_get_items_function"
  passthrough_behavior      = "WHEN_NO_MATCH"
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
  function_name = "todolist_get_items_function"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.todolist_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_call_add_item_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "todolist_add_item_function"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.todolist_api.execution_arn}/*/*"
}