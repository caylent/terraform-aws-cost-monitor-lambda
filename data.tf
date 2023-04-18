data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_kms_secrets" "secret_value" {
  secret {
    name    = "slack_webhook_url"
    payload = var.encripted_slack_webhook_url
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "inline_policy" {
  statement {
    actions = [
      "ce:ListSavingsPlansPurchaseRecommendationGeneration",
      "ce:ListCostAllocationTags",
      "ce:GetCostAndUsage",
      "ce:ListCostCategoryDefinitions",
      "ce:GetCostForecast",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.secret.arn,
      "arn:aws:ce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/GetCostAndUsage",
      "arn:aws:ce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/GetCostForecast",
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"]
  }
}

data "archive_file" "lambda_deployment_package" {
  type        = "zip"
  output_path = local.lambda_package_file
  source_dir  = "${path.module}/lambda/package/"
}