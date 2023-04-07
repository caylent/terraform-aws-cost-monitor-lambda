variable "frequency" {
  description = "number of days to run the lambda (cron formating is also accepted)"
  type        = string
  default     = "rate(1 day)"
}

variable "name" {
  description = "name prefix to be applied to all resources"
  type        = string
  default     = "cost_alert"
}

variable "image_uri" {
  description = "URI of the repo where the lambda image is stored"
  type        = string
}

variable "encripted_slack_webhook_url" {
  description = "encript the webhook URL with KMS, and use it in this variable. See readme.md"
  type        = string
}

variable "alert_threshold" {
  description = "integer representing the % above which alerts will be sent to slack"
  type        = number
}

variable "alerts_only" {
  description = "the lambda will only post messages if a threshold is exceeded (alerts only mode). If set to false (a.k.a. scheduled mode) messages will be sent regularly"
  type        = bool
  default     = true
}