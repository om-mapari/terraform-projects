output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "put_lambda" {
  value = aws_lambda_function.put.function_name
}

output "get_lambda" {
  value = aws_lambda_function.get.function_name
}

output "delete_lambda" {
  value = aws_lambda_function.delete.function_name
}
