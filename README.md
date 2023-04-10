# Cost monitor Lambda
This module builds the infrastructure required to run a Lambda Function to retrieve the current AWS cost and the end of month forecasted cost.
The function can be configured to report it's finding regularly (scheduled mode) or only if certain threshold is exceeded (alerts only mode). In both cases it uses an Slack webhook to send ots findings. Use the input parameter *alerts_only* to define this behaviour.

**Before Running Terraform**
1. Before instantiating the module, [follow these instructions to create an slack webhook](https://api.slack.com/messaging/webhooks)
2. Create a customer manager [KMS key](https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html). Make sure the account Terraform will use to create the infrastructure can use it.
3. [Encript](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_secrets) the slack webhook URL

`echo -n 'slack webhook URL' > plaintext-file`

`aws kms encrypt --key-id <id of CMK created in step 2> --plaintext fileb://plaintext-file --output text --query CiphertextBlob`

4. Use the output of this command as a value for *encripted_slack_webhook_url*. The module will decript it, and store it as a secret in AWS Secrets Manager
5. Manually create an ECR repo. Paste the repo URI in line 4 of /lambda/build.sh as the value for the *ECR_URI* variable.
6. Run `/lambda/build.sh BOOTSTRAP`. By using this argument the script will build an image and push it to ECR. Grab the image URI and use it as value for *image_uri* in the Terraform module. The script can be run without the BOOTSTRAP argument to deploy new versions of the lambda code.
7. Fill the rest of the module input parameters and run Terraform plan/apply


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.60.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.60.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.lambda_trigger](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.event_target](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.iam_for_lambda](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/iam_role) | resource |
| [aws_lambda_function.cost_alert](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_events_bridge_to_run_lambda](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/lambda_permission) | resource |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret_version](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/resources/secretsmanager_secret_version) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.inline_policy](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_secrets.secret_value](https://registry.terraform.io/providers/hashicorp/aws/4.60.0/docs/data-sources/kms_secrets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_threshold"></a> [alert\_threshold](#input\_alert\_threshold) | Integer representing the % above which alerts will be sent to slack | `number` | n/a | yes |
| <a name="input_alerts_only"></a> [alerts\_only](#input\_alerts\_only) | The lambda will only post messages if a threshold is exceeded (alerts only mode). If set to false (a.k.a. scheduled mode) messages will be sent regularly | `bool` | `true` | no |
| <a name="input_encripted_slack_webhook_url"></a> [encripted\_slack\_webhook\_url](#input\_encripted\_slack\_webhook\_url) | Encript the webhook URL with KMS, and use it in this variable. See readme.md | `string` | n/a | yes |
| <a name="input_frequency"></a> [frequency](#input\_frequency) | Frequency to run the lambda (cron formating is also accepted) | `string` | `"rate(1 day)"` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | URI of the repo where the lambda image is stored | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name prefix to be applied to all resources | `string` | `"cost_alert"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | Lambda function ARN |
<!-- END_TF_DOCS -->