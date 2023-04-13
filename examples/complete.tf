
module "cost_Alert_lambda" {
  source                      = "../"
  image_uri                   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/cost_lambda:latest"
  encripted_slack_webhook_url = "AQICAHhwN3YPekhlemIp7nHw+GHjTMTXKc3+L7XA6ZZpitoP4AF+IE7ACHaf3fqlNw8p0sYkAAAAsTCBrgYJKoZIhvcNAQcGoIGgMIGdAgEAMIGXBgkqhkiG9w0BBwEwHgYJYIZIAWUDBAEuMBEEDLIa3UV83p6BcnXBPQIBEIBqEbZn2neWBHw2piUx56jNmj9Gpmr1TaaQ8NJpYZ8lvnENnG3VHt4080Q+RoTjrujDsqx7MJN5aYTEVIxlxbXPNwsGD2ztuJMwDucem8zdOXd5tksXG0HfWHn78BfeE6UdD/7UTEnglN+y9A=="
  alert_threshold             = 20
}






