output "todolist_api_gw_base_url" {
  description = "Base URL for API Gateway stage."
  value = aws_apigatewayv2_stage.todolist_lambda_api_gw_stage.invoke_url
}