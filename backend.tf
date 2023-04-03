terraform {
  backend "s3" {
    bucket = "tfstate-jmpcba"
    key    = "cost_anomaly_detector/cost_lambda.tfstate"
    region = "us-east-1"
  }
}