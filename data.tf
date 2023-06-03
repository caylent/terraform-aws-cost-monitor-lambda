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
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.secret.arn
    ]
  }

  statement {
    actions = [
      "ce:ListSavingsPlansPurchaseRecommendationGeneration",
      "ce:ListCostAllocationTags",
      "ce:GetCostAndUsage",
      "ce:ListCostCategoryDefinitions",
      "ce:GetCostForecast"
    ]
    resources = [
      "arn:aws:ce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/GetCostAndUsage",
      "arn:aws:ce:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/GetCostForecast"
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    ]
  }

}

data "archive_file" "lambda_deployment_package" {
  depends_on = [null_resource.pip_installation]
  type        = "zip"
  source_dir = "${path.module}/lambda"
  output_path = "${path.module}/cost_monitor.zip"
  output_file_mode = "0666"
}