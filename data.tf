data "aws_kms_secrets" "secret_value" {
  secret {
    name    = "slack_webhook_url"
    payload = var.encripted_slack_webhook_url
  }
}