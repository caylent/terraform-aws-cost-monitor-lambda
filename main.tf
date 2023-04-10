resource "aws_lambda_function" "cost_alert" {
  function_name = var.name
  role          = aws_iam_role.iam_for_lambda.arn
  package_type  = "Image"
  image_uri     = var.image_uri

  environment {
    variables = {
      "alert_threshold"     = var.alert_threshold
      "alerts_only"         = var.alerts_only
      "webhook_secret_name" = aws_secretsmanager_secret.secret.name # Do not change the key. It's used by the lambda
    }
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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  path               = "/service-role/"

  inline_policy {
    name   = "read-only-cost-and-usage"
    policy = data.aws_iam_policy_document.inline_policy.json
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
    resources = ["*"]
  }
}

resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name        = "${var.name}-trigger"
  description = "${var.name}-trigger"

  schedule_expression = var.frequency
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.cost_alert.arn
}

resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger.arn
}

resource "aws_secretsmanager_secret" "secret" {
  name = "${var.name}-slack-webhook-url"
}
resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = data.aws_kms_secrets.secret_value.plaintext["slack_webhook_url"]
}