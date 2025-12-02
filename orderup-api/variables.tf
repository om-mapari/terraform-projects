variable "lambda_runtime" {
  default     = "nodejs22.x"
  description = "Runtime for all lambda functions"
}

variable "lambda_role_name" {
  default = "OrderUpLambdaExecutionRole"
}

variable "project_prefix" {
  default = "OrderUpAPI"
}

variable "region" {
  default = "us-east-1"
}


