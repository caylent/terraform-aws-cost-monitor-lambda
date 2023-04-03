output "ecr_uri" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "lambda_arn" {
  value = aws_lambda_function.cost_alert.arn
}