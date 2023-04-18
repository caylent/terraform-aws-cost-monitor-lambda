resource "aws_lambda_function" "cost_alert" {
  function_name    = var.name
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = local.lambda_package_file
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_deployment_package.output_base64sha256
  environment {
    variables = {
      "alert_threshold"     = var.alert_threshold
      "alerts_only"         = var.alerts_only
      "webhook_secret_name" = aws_secretsmanager_secret.secret.name # Do not change the key. It's used by the lambda
    }
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