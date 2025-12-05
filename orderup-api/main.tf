###########################################################
# Provider
###########################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket                   = "my-terraform-state-bucket-ommap1"
    key                      = "dev/terraform.tfstate"
    encrypt                  = true
    use_lockfile             = true
    region                   = "us-east-1"
    shared_credentials_files = ["./.aws/credentials"]
    profile                  = "default"
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["${path.module}/.aws/credentials"]
  profile                  = "default"
}

###########################################################
# IAM ROLE for All Lambda Functions
###########################################################

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach AWSLambdaBasicExecutionRole Policy
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###########################################################
# Lambda ZIP Packaging
###########################################################

data "archive_file" "put_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/orderup-put.mjs"
  output_path = "${path.module}/lambda/orderup-put.zip"
}

data "archive_file" "get_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/orderup-get.mjs"
  output_path = "${path.module}/lambda/orderup-get.zip"
}

data "archive_file" "delete_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/orderup-delete.mjs"
  output_path = "${path.module}/lambda/orderup-delete.zip"
}

###########################################################
# Lambda Functions (PUT, GET, DELETE)
###########################################################

resource "aws_lambda_function" "put" {
  function_name = "${var.project_prefix}_PUT"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime

  filename         = data.archive_file.put_zip.output_path
  source_code_hash = data.archive_file.put_zip.output_base64sha256
}

resource "aws_lambda_function" "get" {
  function_name = "${var.project_prefix}_GET"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime

  filename         = data.archive_file.get_zip.output_path
  source_code_hash = data.archive_file.get_zip.output_base64sha256
}

resource "aws_lambda_function" "delete" {
  function_name = "${var.project_prefix}_DELETE"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime

  filename         = data.archive_file.delete_zip.output_path
  source_code_hash = data.archive_file.delete_zip.output_base64sha256
}

###########################################################
# API Gateway HTTP API
###########################################################

resource "aws_apigatewayv2_api" "orderup_api" {
  name          = var.project_prefix
  protocol_type = "HTTP"
}

###########################################################
# API Integrations (API Gateway → Lambda)
###########################################################

resource "aws_apigatewayv2_integration" "put_integration" {
  api_id = aws_apigatewayv2_api.orderup_api.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.put.invoke_arn
}

resource "aws_apigatewayv2_integration" "get_integration" {
  api_id = aws_apigatewayv2_api.orderup_api.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get.invoke_arn
}

resource "aws_apigatewayv2_integration" "delete_integration" {
  api_id = aws_apigatewayv2_api.orderup_api.id

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.delete.invoke_arn
}

###########################################################
# API Routes
###########################################################

# PUT /order
resource "aws_apigatewayv2_route" "put_route" {
  api_id    = aws_apigatewayv2_api.orderup_api.id
  route_key = "PUT /order"
  target    = "integrations/${aws_apigatewayv2_integration.put_integration.id}"
}

# GET /order
resource "aws_apigatewayv2_route" "get_all_route" {
  api_id    = aws_apigatewayv2_api.orderup_api.id
  route_key = "GET /order"
  target    = "integrations/${aws_apigatewayv2_integration.get_integration.id}"
}

# GET /order/{id}
resource "aws_apigatewayv2_route" "get_single_route" {
  api_id    = aws_apigatewayv2_api.orderup_api.id
  route_key = "GET /order/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.get_integration.id}"
}

# DELETE /order/{id}
resource "aws_apigatewayv2_route" "delete_route" {
  api_id    = aws_apigatewayv2_api.orderup_api.id
  route_key = "DELETE /order/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_integration.id}"
}

###########################################################
# Stage ($default)
###########################################################

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.orderup_api.id
  name        = "$default"
  auto_deploy = true
}

###########################################################
# Lambda Permission for API Gateway to Invoke
###########################################################

resource "aws_lambda_permission" "allow_api_put" {
  statement_id  = "AllowAPIGatewayInvokePUT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.put.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orderup_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_get" {
  statement_id  = "AllowAPIGatewayInvokeGET"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orderup_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_delete" {
  statement_id  = "AllowAPIGatewayInvokeDELETE"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orderup_api.execution_arn}/*/*"
}
