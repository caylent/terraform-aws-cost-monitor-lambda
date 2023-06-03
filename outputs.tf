output "lambda_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.cost_alert.arn
}