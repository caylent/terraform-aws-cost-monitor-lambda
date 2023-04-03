variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "frequency" {
  description = "number of days to run the lambda"
  type        = string
  default     = "rate(1 minute)"
}

variable "name" {
  description = "name prefix to be applied to all resources"
  type        = string
  default     = "cost_alert"
}

variable "image_uri" {
  description = "URI of the repo where the lambda image is stored"
  type = string
  default = "public.ecr.aws/lambda/python:3.8" #basic lambda image. Change it to the ECR URI once the code is pushed to ECR
}